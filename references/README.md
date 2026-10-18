# Starter bibliography

`refs.yaml` is a minimal DOI-verified starter bibliography for the manuscript
backbone. It is deliberately not a complete literature review or a canonical
Zotero/Better BibTeX export. Before circulation or submission, reconcile it
against the authors' library and add the sources needed for the final framing,
methods, data provenance, and discussion.

The initial five entries were checked against Crossref metadata and the publisher or
journal landing page on 2026-09-12. The requested identifiers and citation
keys are retained exactly:

| Key | DOI-verified record | Confirmed scope relevant here |
| --- | --- | --- |
| `Burton2015` | [Burton et al. (2015)](https://doi.org/10.1111/1365-2664.12432), *Journal of Applied Ecology* 52(3):675-685 | Review of wildlife-camera-trap studies, including sampling error, imperfect detection, deployment/reporting practices, and links between survey measurements and ecological processes. |
| `Steenweg2017` | [Steenweg et al. (2017)](https://doi.org/10.1002/fee.1448), *Frontiers in Ecology and the Environment* 15(1):26-34 | Review proposing interconnected remote-camera networks for biodiversity monitoring, with emphasis on shared protocols, metadata, collaboration, and scale. The publisher records first online publication on 20 December 2016; the volume and citation year are 2017. |
| `KaplanMeier1958` | [Kaplan and Meier (1958)](https://www.tandfonline.com/doi/abs/10.1080/01621459.1958.10501452), *Journal of the American Statistical Association* 53(282):457-481 | Introduces the product-limit estimate for survival with incomplete observations and discusses assumptions about event and loss times. |
| `Cox1972` | [Cox (1972)](https://academic.oup.com/jrsssb/article/34/2/187/7027194), *Journal of the Royal Statistical Society: Series B (Methodological)* 34(2):187-202 | Develops regression for censored failure times with covariate effects in the hazard and an unspecified baseline hazard, using conditional likelihood. |
| `Wei1992` | [Wei (1992)](https://onlinelibrary.wiley.com/doi/abs/10.1002/sim.4780111409), *Statistics in Medicine* 11(14-15):1871-1879 | Reviews accelerated-failure-time regression for censored survival data, including its log-survival-time interpretation and use as an alternative to Cox regression. |

Crossref records used for metadata checking are available at
<https://api.crossref.org/works/{doi}> with each DOI URL-decoded as the final
path component. The DOI and publisher links in the table are the preferred
stable citation links.

The bibliography is not activated as a target-journal bibliography yet. The
CSL in `csl/author-date.csl` is a journal-neutral development style; select and
verify the target journal style after the venue decision.

## October 18 editorial additions

Two sources were checked against the journal/publisher records and accessible
article text on 18 October 2026:

| Key | Verified source | Use in this manuscript |
| --- | --- | --- |
| `RoystonParmar2013` | [Royston and Parmar (2013)](https://pmc.ncbi.nlm.nih.gov/articles/PMC3922847/), *BMC Medical Research Methodology* 13:152; DOI 10.1186/1471-2288-13-152 | Identifies the finite-horizon area under a survival curve as restricted mean survival time. The manuscript does not claim this identity as a new method or import causal interpretation from the article's trial setting. |
| `Solow2005` | [Solow (2005)](https://www.sciencedirect.com/science/article/pii/S0025556405000350), *Mathematical Biosciences* 195(1):47–55; DOI 10.1016/j.mbs.2005.02.001 | Supports the distinction between last observation and an unobserved endpoint, and the relevance of the observation process. Used as a brief analogy; no extinction estimator is applied to the camera records. |

Solow (1993) was proposed during discussion but only its bibliographic record
was verified in this pass. The text instead cites the accessible 2005 paper.
No claim that this is the first survival analysis of camera batteries is made.
