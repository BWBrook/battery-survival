#!/usr/bin/env python3
"""Apply small, reproducible layout repairs to a generated manuscript DOCX.

The formatter deliberately works at the OOXML package level.  It changes page
geometry, pagination hints and table layout;
document text, relationships and media are copied through unchanged.

Usage::

    python3 scripts/format_manuscript_docx.py INPUT.docx [OUTPUT.docx]
"""

from __future__ import annotations

import argparse
import copy
import os
import re
import sys
import tempfile
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


NS = {
    "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "pr": "http://schemas.openxmlformats.org/package/2006/relationships",
    "ct": "http://schemas.openxmlformats.org/package/2006/content-types",
    "xml": "http://www.w3.org/XML/1998/namespace",
}

for _prefix, _uri in NS.items():
    if _prefix not in {"pr", "ct", "xml"}:
        ET.register_namespace(_prefix, _uri)
ET.register_namespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
ET.register_namespace("m", "http://schemas.openxmlformats.org/officeDocument/2006/math")
ET.register_namespace("wp", "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing")
ET.register_namespace("pic", "http://schemas.openxmlformats.org/drawingml/2006/picture")
ET.register_namespace("mc", "http://schemas.openxmlformats.org/markup-compatibility/2006")

W = NS["w"]
R = NS["r"]
Q = lambda ns, local: f"{{{NS[ns]}}}{local}"

A4_WIDTH_TWIPS = 11906
A4_HEIGHT_TWIPS = 16838
MARGIN_TWIPS = 1417  # 2.5 cm, rounded to the nearest twentieth of a point
TEXT_WIDTH_TWIPS = A4_WIDTH_TWIPS - (2 * MARGIN_TWIPS)


def _tag(element: ET.Element) -> str:
    return element.tag.rsplit("}", 1)[-1]


def _child(parent: ET.Element, namespace: str, local: str) -> ET.Element | None:
    return parent.find(Q(namespace, local))


def _ensure_child(parent: ET.Element, namespace: str, local: str) -> ET.Element:
    found = _child(parent, namespace, local)
    if found is None:
        found = ET.SubElement(parent, Q(namespace, local))
    return found


def _set_attr(element: ET.Element, namespace: str, local: str, value: str) -> None:
    element.set(Q(namespace, local), value)


def _paragraph_text(paragraph: ET.Element) -> str:
    return "".join(paragraph.itertext())


def _paragraph_has_content(paragraph: ET.Element) -> bool:
    """Return whether a paragraph has visible/content-bearing material."""

    for element in paragraph.iter():
        if element is paragraph or _tag(element) in {"pPr", "rPr", "bookmarkStart", "bookmarkEnd"}:
            continue
        if _tag(element) == "t" and (element.text or "").strip():
            return True
        if _tag(element) in {"drawing", "object", "pict", "oMath", "oMathPara", "tab", "sym", "fldChar", "instrText"}:
            return True
        if _tag(element) == "br" and (element.get(Q("w", "type")) or "text") != "page":
            return True
    return False


def _is_page_break_only(paragraph: ET.Element) -> bool:
    if _child(paragraph, "w", "pPr") is not None and _child(paragraph.find(Q("w", "pPr")), "w", "sectPr") is not None:
        return False
    saw_break = False
    for element in paragraph.iter():
        if element is paragraph or _tag(element) in {"pPr", "rPr", "bookmarkStart", "bookmarkEnd"}:
            continue
        name = _tag(element)
        if name == "br" and (element.get(Q("w", "type")) or "text") == "page":
            saw_break = True
            continue
        # Runs and their properties are structural wrappers, not content.
        if name in {"r", "proofErr", "lastRenderedPageBreak"}:
            continue
        return False
    return saw_break


def _insert_page_break_before(paragraph: ET.Element) -> None:
    ppr = _ensure_child(paragraph, "w", "pPr")
    if _child(ppr, "w", "pageBreakBefore") is not None:
        return
    # Keep the pPr child order valid for Word/LibreOffice. pageBreakBefore is
    # after keepNext/keepLines and before the remaining paragraph properties.
    insert_at = len(ppr)
    after = {
        "framePr", "widowControl", "numPr", "suppressLineNumbers", "pBdr", "shd",
        "tabs", "spacing", "ind", "contextualSpacing", "jc", "textDirection",
        "textAlignment", "outlineLvl", "divId", "cnfStyle", "rPr", "sectPr",
    }
    for index, child in enumerate(ppr):
        if _tag(child) in after:
            insert_at = index
            break
    ppr.insert(insert_at, ET.Element(Q("w", "pageBreakBefore")))


def move_page_break_paragraphs(body: ET.Element) -> int:
    """Move direct-body page-break-only paragraphs to following content p's."""

    moved = 0
    children = list(body)
    for index, element in enumerate(children):
        if _tag(element) != "p" or not _is_page_break_only(element):
            continue
        target = None
        for candidate in children[index + 1 :]:
            if _tag(candidate) == "p" and _paragraph_has_content(candidate):
                target = candidate
                break
            if _tag(candidate) == "sectPr":
                break
        if target is None:
            continue
        _insert_page_break_before(target)
        body.remove(element)
        moved += 1
    return moved


def set_page_geometry(root: ET.Element) -> int:
    sections = root.findall(f".//{Q('w', 'sectPr')}")
    for sect in sections:
        page_size = _ordered_child(
            sect,
            "pgSz",
            {"pgMar", "paperSrc", "pgBorders", "lnNumType", "pgNumType", "cols", "formProt", "vAlign", "noEndnote", "titlePg", "textDirection", "bidi", "rtlGutter", "docGrid", "printerSettings", "sectPrChange"},
        )
        _set_attr(page_size, "w", "w", str(A4_WIDTH_TWIPS))
        _set_attr(page_size, "w", "h", str(A4_HEIGHT_TWIPS))
        page_size.attrib.pop(Q("w", "orient"), None)
        margins = _ordered_child(
            sect,
            "pgMar",
            {"paperSrc", "pgBorders", "lnNumType", "pgNumType", "cols", "formProt", "vAlign", "noEndnote", "titlePg", "textDirection", "bidi", "rtlGutter", "docGrid", "printerSettings", "sectPrChange"},
        )
        for side in ("top", "bottom", "left", "right"):
            _set_attr(margins, "w", side, str(MARGIN_TWIPS))
        _set_attr(margins, "w", "header", margins.get(Q("w", "header"), "720"))
        _set_attr(margins, "w", "footer", margins.get(Q("w", "footer"), "720"))
        _set_attr(margins, "w", "gutter", margins.get(Q("w", "gutter"), "0"))
    return len(sections)


def _set_or_add(element: ET.Element, local: str, attrs: dict[str, str]) -> ET.Element:
    child = _child(element, "w", local)
    if child is None:
        child = ET.SubElement(element, Q("w", local))
    for key, value in attrs.items():
        child.set(Q("w", key), value)
    return child


def _ordered_child(parent: ET.Element, local: str, before: set[str]) -> ET.Element:
    """Get/create a child and place it before the first later-schema child."""

    child = _child(parent, "w", local)
    if child is not None:
        return child
    child = ET.Element(Q("w", local))
    for index, existing in enumerate(parent):
        if _tag(existing) in before:
            parent.insert(index, child)
            return child
    parent.append(child)
    return child


def _set_table_width(table: ET.Element, widths: list[int]) -> None:
    tbl_pr = _ensure_child(table, "w", "tblPr")
    _set_or_add(tbl_pr, "tblW", {"type": "dxa", "w": str(sum(widths))})
    layout = _ordered_child(tbl_pr, "tblLayout", {"tblLook", "tblCaption", "tblDescription"})
    _set_attr(layout, "w", "type", "fixed")

    grid = _ensure_child(table, "w", "tblGrid")
    for col in list(grid):
        grid.remove(col)
    for width in widths:
        ET.SubElement(grid, Q("w", "gridCol"), {Q("w", "w"): str(width)})

    for row in table.findall(Q("w", "tr")):
        for col_index, cell in enumerate(row.findall(Q("w", "tc"))):
            if col_index >= len(widths):
                continue
            tc_pr = _ensure_child(cell, "w", "tcPr")
            tc_w = _child(tc_pr, "w", "tcW")
            if tc_w is None:
                tc_w = ET.SubElement(tc_pr, Q("w", "tcW"))
            _set_attr(tc_w, "w", "type", "dxa")
            _set_attr(tc_w, "w", "w", str(widths[col_index]))


def _compact_table_cells(table: ET.Element) -> None:
    for row in table.findall(Q("w", "tr")):
        tr_pr = _ensure_child(row, "w", "trPr")
        if _child(tr_pr, "w", "cantSplit") is None:
            tr_pr.insert(0, ET.Element(Q("w", "cantSplit")))
        for paragraph in row.findall(f".//{Q('w', 'p')}"):
            ppr = _ensure_child(paragraph, "w", "pPr")
            spacing = _ordered_child(
                ppr,
                "spacing",
                {"ind", "contextualSpacing", "mirrorInd", "suppressOverlap", "jc", "textDirection", "textAlignment", "outlineLvl", "divId", "cnfStyle", "rPr", "sectPr"},
            )
            for local, value in (("before", "0"), ("after", "0"), ("line", "240"), ("lineRule", "auto")):
                _set_attr(spacing, "w", local, value)
        for run in row.findall(f".//{Q('w', 'r')}"):
            rpr = _ensure_child(run, "w", "rPr")
            _set_or_add(rpr, "sz", {"val": "20"})
            _set_or_add(rpr, "szCs", {"val": "20"})


def _keep_table_rows_together(table: ET.Element) -> None:
    """Keep the small headline table together when it would orphan a row."""

    rows = table.findall(Q("w", "tr"))
    for row in rows[:-1]:
        for paragraph in row.findall(f".//{Q('w', 'p')}"):
            _ordered_child(
                _ensure_child(paragraph, "w", "pPr"),
                "keepNext",
                {"keepLines", "keepTogether", "widowControl", "pageBreakBefore", "framePr", "numPr", "spacing", "ind", "jc", "rPr", "sectPr"},
            )


def _caption_key(text: str) -> str | None:
    match = re.match(r"^Table\s+(S?\d+)\.", text.strip(), re.IGNORECASE)
    return match.group(1).upper() if match else None


def _table_column_count(table: ET.Element) -> int:
    grid = table.find(Q("w", "tblGrid"))
    if grid is not None and len(grid):
        return len(grid)
    return max((len(row.findall(Q("w", "tc"))) for row in table.findall(Q("w", "tr"))), default=0)


TABLE_WIDTHS_BY_CAPTION = {
    # Main text: brand, chemistry, intervals, median CI, hazard-ratio CI.
    "1": [1900, 1300, 1500, 2300, 2072],
    # Main text: days, cheaper profile, Weibull CI, loglogistic CI, at-risk.
    "2": [700, 1372, 2600, 2600, 1800],
    # Supplementary tables retain the established compact AIC and cohort layouts.
    "S1": [2200, 1600, 1800, 1700, 1772],
    "S2": [1700, 1900, 1300, 2000, 2172],
    "S3": [1700, 1400, 1800, 2200, 1972],
    "S4": [1300, 1300, 1900, 1900, 1300, 1372],
    "S5": [2672, 1500, 1900, 1900, 1100],
}
TABLE_WIDTHS_BY_COLUMN_COUNT = {
    5: [1800, 1600, 1700, 2000, 1972],
    6: [1300, 1300, 1900, 1900, 1300, 1372],
}


def format_tables(root: ET.Element) -> int:
    body = root.find(f".//{Q('w', 'body')}")
    if body is None:
        raise ValueError("document.xml has no document body")
    tables = list(body.findall(Q("w", "tbl")))
    body_children = list(body)
    for table in tables:
        table_index = body_children.index(table)
        caption = None
        caption_key = None
        for prior in reversed(body_children[:table_index]):
            if _tag(prior) != "p":
                continue
            caption_key = _caption_key(_paragraph_text(prior))
            if caption_key is not None:
                caption = prior
                break
        column_count = _table_column_count(table)
        widths = TABLE_WIDTHS_BY_CAPTION.get(caption_key or "", TABLE_WIDTHS_BY_COLUMN_COUNT.get(column_count))
        if widths is None:
            # Keep arbitrary future tables readable without imposing a new
            # scientific or document-specific layout contract.
            if column_count <= 0:
                continue
            base, remainder = divmod(TEXT_WIDTH_TWIPS, column_count)
            widths = [base + (1 if index < remainder else 0) for index in range(column_count)]
        if len(widths) != column_count:
            widths = TABLE_WIDTHS_BY_COLUMN_COUNT.get(column_count)
        if widths is None or len(widths) != column_count:
            raise ValueError(f"no table width mapping for caption={caption_key!r}, columns={column_count}")
        _set_table_width(table, widths)
        _compact_table_cells(table)
        if caption_key in {"1", "S4"}:
            _keep_table_rows_together(table)
        if caption is not None:
            caption_ppr = _ensure_child(caption, "w", "pPr")
            _ordered_child(
                caption_ppr,
                "keepNext",
                {"keepLines", "keepTogether", "widowControl", "pageBreakBefore", "framePr", "numPr", "spacing", "ind", "jc", "rPr", "sectPr"},
            )
    return len(tables)


def _xml_bytes(root: ET.Element) -> bytes:
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def format_docx(input_path: Path, output_path: Path) -> dict[str, int]:
    if input_path.resolve() == output_path.resolve():
        raise ValueError("input and output DOCX paths must differ")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(input_path, "r") as source:
        package = {info.filename: (copy.copy(info), source.read(info.filename)) for info in source.infolist()}
    if "word/document.xml" not in package:
        raise ValueError("input DOCX has no word/document.xml")

    document_root = ET.fromstring(package["word/document.xml"][1])
    body = document_root.find(f".//{Q('w', 'body')}")
    if body is None:
        raise ValueError("document.xml has no document body")
    text_tags = {Q("w", "t"), "{http://schemas.openxmlformats.org/officeDocument/2006/math}t"}
    text_before = [(e.tag, e.text) for e in document_root.iter() if e.tag in text_tags]
    moved_breaks = move_page_break_paragraphs(body)
    sections = set_page_geometry(document_root)
    tables = format_tables(document_root)
    for para in body.findall(Q("w", "p")):
        if re.match(r"^(Table\s+(?:S)?\d+\.|Fig\. (?:S)?\d+\.)", _paragraph_text(para).strip()):
            _ordered_child(
                _ensure_child(para, "w", "pPr"),
                "keepLines",
                {"keepTogether", "widowControl", "pageBreakBefore", "framePr", "numPr", "spacing", "ind", "jc", "rPr", "sectPr"},
            )
    if text_before != [(e.tag, e.text) for e in document_root.iter() if e.tag in text_tags]:
        raise ValueError("layout formatting changed prose or math text")

    package["word/document.xml"] = (package["word/document.xml"][0], _xml_bytes(document_root))
    with zipfile.ZipFile(output_path, "w") as target:
        for filename, (info, data) in package.items():
            target.writestr(info, data)
    return {"sections": sections, "moved_page_breaks": moved_breaks, "tables": tables}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path, nargs="?", help="output DOCX; omit to replace input atomically")
    args = parser.parse_args(argv)
    output = args.output
    temporary = None
    if output is None:
        # Keep the input untouched until the complete replacement package has
        # been written successfully.  The caller may therefore use one path.
        handle, temporary_name = tempfile.mkstemp(prefix=f".{args.input.stem}-formatted-", suffix=".docx", dir=args.input.parent)
        os.close(handle)
        temporary = Path(temporary_name)
        output = temporary
    try:
        stats = format_docx(args.input, output)
        if temporary is not None:
            os.replace(temporary, args.input)
    except (OSError, ET.ParseError, ValueError, zipfile.BadZipFile) as error:
        if temporary is not None:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass
        print(f"format_manuscript_docx.py: error: {error}", file=sys.stderr)
        return 2
    print(
        f"formatted {args.input} -> {args.input if args.output is None else output}; "
        f"sections={stats['sections']} moved_page_breaks={stats['moved_page_breaks']} "
        f"tables={stats['tables']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
