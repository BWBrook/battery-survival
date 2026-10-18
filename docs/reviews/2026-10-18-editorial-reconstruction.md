# Editorial reconstruction, 18 October 2026

## Mandate and status

Barry asked Codex and Claude to substantially rework the manuscript for both a
general ecology editor and a specialist reader. His full request and Codex's
first proposition are in Correspondence thread 91, message 1914. The starting
publication source was the 29 September draft at commit `7d8d443`. An assembled
revision has now been built and checked following Claude's counterproposal;
the original proposition below is retained to show the editorial choice.

The intended change is structural: give the study a clear empirical argument,
select the displays that carry it, and put technical detail where it supports
that argument. New model fitting, changed estimands and release are not part
of this editorial work.

## First proposition and its strongest objection

Organising question: **What does it cost to keep a camera survey observing
until its next visit?**

Contribution: field survival records connect battery expenditure to retained
observation time under an explicit revisit policy, while a failed regional
transfer check shows why strong local associations do not establish a portable
purchasing rule.

The three substantive results are large local endurance contrasts, a change
in the economic comparison between 90- and 120-day revisits, and longer
observed survival in the held region despite greater flash workload. Model
comparison and camera-dependence checks support these results; they should
not dominate the main displays. Candidate main figures are the observed
survival curves, the price/observation-time comparison, and the held-region
observed/predicted contrast. The current calibration and conditional-optimum
figures belong in the supplement if this architecture survives critique.

The strongest objection is that the economic scenarios combine different
brands with different regions, seasons and retrospective workloads. They
cannot answer what would happen if a manager switched batteries at the same
site. If that boundary makes the purchasing question carry too much weight,
the alternative is to lead with **battery reliability as a component of
survey effort**, using the economic calculation as a worked application.
Claude has been asked to challenge the choice between these arguments.

No claim of a new statistical method is proposed. No priority claim about the
first survival analysis of camera batteries has been verified in this pass.
The contribution must stand on the empirical evidence and its use, without
relying on either claim.

## Initial candidate opening for critique

A camera survey scheduled to run for four months does not necessarily deliver
four months of observation. If batteries fail between visits, replacing them
restores the camera but cannot recover the missed part of the survey. Where
operation is not monitored, deployment dates can also overstate the time
during which animals could have been detected. Camera reliability therefore
connects field logistics to the observation process on which ecological
inference depends [@Burton2015; @Steenweg2017].

Battery price alone cannot resolve this problem. A cheaper set saves money
at installation; a longer-lasting set may preserve observation time before
the next visit. Which saving matters more depends on the visit interval and
on the survey's need for continuity. Field experience shows that battery
endurance varies with operating conditions [@Newey2015], but translating that
variation into a decision requires the expected time lost, not simply a
typical battery lifetime. It also requires an explicit judgement about the
value of a missed camera-day.

We connect these quantities using 3,216 deployment intervals from 489 cameras
in a Tasmanian field network. We first estimate differences in recorded
endurance, then express the price premium for a longer-lasting set as a
break-even value of retained observation time at 90- and 120-day revisits.
Finally, we test how well the fitted relationships transfer to another region
of the same network. The records identify last confirmed operation rather
than physical shutdown, and the economic comparisons describe observed
operating scenarios rather than controlled battery substitutions. Together,
the analyses ask what routine servicing records can contribute to survey
design, and where local evidence remains necessary.

## Checks on the September worked examples

These are read-only arithmetic and source checks, not new model validation.

| Quantity | Verified value | Source |
|---|---|---|
| Wallaby at 120 days, relative to Energizer | Saves 16 units; 11.219 Weibull / 11.696 loglogistic additional modelled lost days | `outputs/management/2026-09-19/break_even/break_even_estimates.csv`; `120 * downtime_gap_mean` |
| Varta at 120 days, relative to Energizer | Saves 4 units; 2.494 / 2.618 additional modelled lost days | Same CSV and calculation |
| Supported lithium thresholds at 120 days | 1.36799–1.64542 illustrative units per lost day | Same CSV; excludes Procell beyond joint-cell follow-up |
| All alternative thresholds at 90 days | 2.30930–9.91084 units per lost day | Same CSV |
| Additional lost days for cheaper lithium scenarios at 90 days | Maximum 2.40438 | Same CSV; `90 * downtime_gap_mean` |
| Brand KM survival at 120 days | Energizer 0.897325; Varta 0.871066; Wallaby 0.345321; Procell 0.069696 | `outputs/sensitivity/2026-09-17/tables/aft_calibration_bb.csv`; observed estimates identical across fitted-model rows |
| Training records longer than 91 days | 2,527 / 3,216 = 78.5759% | Read-only count of `data/batt_life_aug22.csv` for `ct`, `se`, `nw`, `wt`; matches configured training regions; no active exclusions |
| Procell white-flash Central/winter support | Maximum 117 days; 22 intervals/cameras at risk at 90 days; zero at 120 days | Corrected break-even CSV |

Two interpretive corrections should enter the assembled revision:

- Average expenditure per active camera-day does not establish a lower bound
  on the marginal scientific value of a lost day. Remove the current
  revealed-value inference; local costs and observation priorities are
  separate inputs.
- A scheduled daily test image could narrow the operation-time gap if
  scheduling, recording and retrieval are reliable. It does not unconditionally
  identify shutdown within a day, and the protocol's effect on battery use
  needs consideration.

## Acceptance test

After its title, abstract and opening page, an ecology editor should be able
to identify what was learned, why it matters, the contribution beyond a battery
ranking, and the main inference limit. A specialist should be able to trace
the estimates and distinguish local associations, conditional illustrations
and the support-limited transfer test. Agent agreement alone is not validation.

## Assembled revision after the exchange

Claude's message 1927 argued for survey effort as the organising idea, with
money as an application. This resolves the strongest objection to the first
proposition: the paper need not promise a portable purchasing rule to explain
why endurance matters. The opening now moves from nominal deployment length
to expected observation time, names restricted mean survival time, and then
introduces the field evidence. The title is **How battery endurance and revisit
schedules shape camera-trap effort**.

The results follow three questions: how endurance differed within the network;
how much additional modelled time was lost at 90 versus 120 days; and whether
the endurance models transferred to the held region. Three main figures carry
those results. The new lost-days display uses positive-horizon multiplication
of the saved paired downtime summaries, preserving uncertainty and withholding
Procell at 120 days. The new SW display separates observed uncertainty from
the range across six model specifications. The Cox, training-calibration and
conditional-interval displays are retained as supplementary diagnostics.

The discussion develops implications for effort accounting before purchase
costs, transfer and better operation records. Both interpretive corrections
above are implemented. A last-sighting/extinction analogy, suggested by Claude,
explains the endpoint problem using Solow (2005); it does not estimate a gap.
Royston and Parmar (2013) supplies the restricted-mean reference. Both sources
were checked against primary publications. The abstract is 190 words.

An independent wording review prompted three repairs: count failed deployment
intervals rather than cameras; keep camera-effect stability conditional on
the fitted models; and describe expected lost time as a modelled quantity.
The numerical rows of the two main tables remain unchanged. The original
training associations, endpoint convention, retrospective rates, varying
scenario conditions, joint-cell support and limited SW test remain explicit.

## Endpoint-gap work and next writing pass

Claude separately produced a response-only endpoint perturbation in new files,
documented in `docs/log/2026-10-18-endpoint-gap.md`. Codex's message 1943 challenged
its rate interpretation, use of a global duration cap, fixed workload inputs,
support handling and pooling of decision quantities. Claude's message 1952
reports corrections and reruns, including a factor-index price bug he found.
Those new results have not been incorporated or independently numerically
audited in this draft. They concern sufficiency under constructed gap
assumptions, not identification of physical shutdown or diagnosis of the
daylight association. His reported suite results are separate from the checks
performed for this editorial package.

Claude receives the manuscript and captions for a direct writing pass after
the assembled revision is committed. The next exchange should judge whether
the opening and displays now establish a clear contribution for an ecology
editor, and whether a narrowly worded endpoint sensitivity belongs in the
main robustness paragraph and supplement. Build and visual checks, including
minor Word pagination limitations, are recorded in
`docs/log/2026-10-18-editorial.md`.
