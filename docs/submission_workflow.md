# Battery survival: workflow from author read to submission

Started 23 October 2026. Barry and Claude only for this phase; the Codex
exchange is paused and will reopen for revisions. Update the status lines here
as stages close.

**Starting point:** commit `2322333` on `manuscript-draft-2026-09`. The question
title was settled by Barry on 18 October 2026.

**Rules for the phase**

- **The analysis is frozen.** A request for new analysis must name the claim
  at risk and say what the analysis would resolve.
- **Barry does the outward-facing steps:** sends emails, deposits archives,
  posts the preprint and submits. Claude prepares every package and does the
  integration, builds and checks.
- **Every circulated or submitted version is a tagged commit,** so a reviewer's
  comments can always be traced to the exact text they read.

---

## 1. Barry's read — IN PROGRESS

**Files** (Track Changes and comments; the build never overwrites these):

- `manuscript/review/2026-10-23-barry/battery-survival-main_2322333_BWB.docx`
- `manuscript/review/2026-10-23-barry/battery-survival-supplement_2322333_BWB.docx`

From Windows: `\\wsl.localhost\Ubuntu-24.04\home\bwbrook\papers\battery-survival\manuscript\review\2026-10-23-barry\`

**Suggested sittings**

1. **Meaning (about an hour).** Read the title, abstract, Figs 1–3, Tables 1–3,
   Discussion and Conclusions. Ask two questions:
   - Does the paper say what you intended?
   - Is anything claimed that you would not defend to a field ecologist?
2. **Accuracy.** Read Methods and the supplement. At the Methods placeholder,
   answer the six field-methods questions
   (`docs/field_methods_author_questions.md`) in a comment. Mark each answer as
   known, uncertain or "ask Jessie/Zach". Rough notes are enough.

Short comments are enough: "too strong", "unclear", "not how we did it" or
"doesn't sound like me" are all actionable. You need not rewrite prose.

**What changed since your September read**

- The question title.
- A rewritten, quantitative abstract.
- New Fig. 2, showing lost camera-days against revisit interval with 5% and
  10% loss lines.
- New Table 2, the longest revisit interval at a 5% or 10% loss tolerance. The
  old cost table is now Table 3.
- Supplement S8, the last-image gap stress test, and S9, curve and tolerance
  methods.
- Figs S4 and S5.
- Consistent battery colours across figures.

**Facts only Barry can supply** (chat is fine; see the facts sheet below).

**Exit:** marked-up files saved back in the review folder, plus facts-sheet
answers.

## 2. Circulation preparation (Claude) — NOT STARTED

- **Integrate the read.** Merge Barry's edits into `main.md` and `supplement.md`.
  Write the field-methods prose. List any comment that needs a decision rather
  than guessing.
- **Front and back matter:**
  - authors and affiliations, corresponding author;
  - CRediT contributions, proposed from the record for Barry to confirm;
  - funding, acknowledgements, ethics and permits, competing interests;
  - a draft data-availability statement;
  - an AI-use disclosure. It must meet the journal's policy and Barry's
    standard: each system named with its version, its role, and how its output
    was validated.
- **Remove** the draft banner and the field-methods placeholder.
- **Checks:**
  - A targeted literature-completeness check by a fresh subagent: battery
    performance, camera operation and downtime, survey effort.
  - Every reference checked against the claim it supports.
  - Every changed number checked against its pipeline output.
  - One context-free editor read of the final text.
- **Build and tag** `coauthor-review-v1`.
- **Co-author package:**
  - a draft email for Barry to send;
  - dated main and supplement Word files;
  - a one-page review note covering:
    - priorities: field accuracy, interpretation, management relevance, missing
      literature;
    - questions assigned to Jessie or Zach;
    - the proposed author order, the Wildlife Research target and the preprint
      intention;
    - the AI-use summary and a two-week window.

**Gate:** Barry approves the package. Claude raises any edit that would change
a claim or a reported number before making it.

**Exit:** Barry sends the email.

## 3. Co-author review (Jessie Buettel, Zach Aandahl) — NOT STARTED

About two weeks. Stage 4 runs alongside.

## 4. Release and submission materials (Claude, alongside stage 3) — NOT STARTED

Barry needs to decide (Claude will bring recommendations):

- what goes public: the raw CSV, analysis code, and the saved fits or only
  derived tables;
- whether camera identifiers are kept or pseudonymised. They carry site codes
  (`JR-`, `LH-S4-`, `AF-S10-`, `SW-`), but no coordinates;
- licences: CC BY 4.0 for data and MIT for code are the default proposal;
- the archive: Zenodo via a GitHub release, or the UTAS repository;
- whether the human–AI correspondence record is published with the work. This
  needs the co-authors' agreement;
- the preprint server, possibly after an eligibility inquiry about AI-assisted
  drafting.

Claude then:

- builds the standalone reproduction package and tests it from a clean clone;
- drafts the cover letter, the journal's required extras (summary text and
  table-of-contents image) and declarations;
- proposes suggested reviewers for Barry to vet.

## 5. Consolidate co-author comments (Claude) — NOT STARTED

- Merge compatible edits into one master source.
- Prepare a response table that gives a proposed disposition for every
  substantive comment.
- Barry decides the consequential items.
- A request for analysis must pass the frozen-analysis rule above.

## 6. Final approval (all authors) — NOT STARTED

All authors explicitly approve:

- the manuscript;
- the author order;
- the data and code release;
- the preprint server and licence.

Then tag `submitted-v1` and merge to `main`.

## 7. Release, preprint, submit (Barry) — NOT STARTED

Run in order:

1. Deposit the archive and obtain its DOI.
2. Post the preprint.
3. Submit to Wildlife Research, with the preprint and archive links in the
   cover letter and data-availability statement.

---

## Facts sheet (Barry)

| Item | Answer |
|---|---|
| Author list and order | |
| Affiliations, ORCIDs | |
| Corresponding author and email | |
| Funding (grant numbers) | |
| Acknowledgements (field staff, landholders, volunteers) | |
| Permits or ethics relevant to the camera network | |
| Data ownership: permission to release the battery records publicly | |
| Competing interests: were any batteries or cameras donated, discounted or supplied by a manufacturer? | |
| Preprint: yes or no; any server preference | |
| Publish the human–AI correspondence with the work? | |
