# Battery life paper: structural plan

## Notes: 
- Target journal: Wildlife Research or Wildlife Society Bulletin
- We are opting for a conventional MSS structure – with some sub-headings for the intro and discussion where needed. 
- Barry to do all analyses initially using Cox proportional hazard modelling framework (which can be presented alongside Zac’s or Zac’s analysis substituted for it later). 
- Need GitHub site include hosting the datasets.
- Present this as half camera trapping manual and half results paper.

## Introduction

P1 
- General introduction to camera trapping.

P2 
– Briefly describe common decisions that need to be made when camera trapping. 
- Not a lot of thought is given to battery type nor how camera settings have an impact – this is a key knowledge gap.

P3 
- Though this knowledge gap makes sense, because the choice of battery type between rechargeable, cheap alkaline or expensive lithium batteries is not straightforward. Even among those categories there are different qualities (particularly for lithium batteries, due to the way they are manufactured).
-Briefly describe the battery types and outline some of their advantages and disadvantages.
-Known issues of alkaline batteries based on their chemistry i.e., contain a paste which is temperature sensitive and can freeze, being particularly vulnerable to cold conditions. Can compare TAS to Europe and North America (similar cool conditions and lots of camera monitoring). Issue of moisture in tropics.
-Benefit of lithium batteries, we a priori expect them to not be impacted by cooler conditions.

P4 
– Drawing in the literature -- The usual course of action for researchers engaged in camera trapping is to not labour on the battery decision and go as cheap as possible with lithium (supporting short-term studies; gather citations on this). But as we move to a need for longer-term monitoring (describe how and why), this just won’t cut it.
- And why do we care about batt life: all else being equal we want the batteries to last as long as possible, simply because premature dead cameras lose data. We deploy them to last and in an ideal scenario we don’t worry about battery life. But in the more usual, not ideal scenario battery choice is an important part of the calculation. 
-Importance of maintaining high service intervals and low disturbance to the sites (so the longer the better for wildlife detection).

P5 
-So therefore: aims of this study with recommendations as an outcome.
-We provide a camera ‘practitioners guide’.
-Other papers don’t look at the detail – we seek to use empirical data to make specific recommendations.


## Methods

Display items:
-Map of the Tas cam network we are using. 
-Photograph of the battery types

-Describing the final datasets (methods) plus description of the experiments/data (e.g., field campaign). 

### Experiments 

1 
-Dataset of deliberate battery drains (measuring energy loss)
-Deliberate energy drain (vs reported) to show how much variance. Can calculate therefore how long the batteries might last. 

2 
- PIR test experiment: Bench test with black IR (baseline test for passive IR sensor) – were only triggered once a day in a dark room but otherwise left on passive IR sensor until they died. Great dataset!
- This experiment can also give a base expectation of how long the cameras last with the batteries. Provides a contrast of field conditions. 


### Field data

-Live datasets from field (3 types of flash used: black and white IRs and white flashes).
Will argue why we chose Cuddeback exchange cameras (main reason: exchangeable flash feature = big advantage of our experiment) – controlling for camera unit! 
-Battery types used in the field: we tested 1 basic alkaline type and a range of different qualities of lithium batteries. Only alkaline we tested was Duracell Procell (commercial grade copper top and another that Greg used might also be included depending on sample size).
-Describe TasCam (only details relevant to the battery life dataset i.e., duration of deployments).
-Treatment of the data: a wide variety of situations were covered in our field deployment. That is, some of our cameras would be operating, and others might have failed. Why did cameras fail early: can be cell failure, or an issue with the camera. We removed chronically underperforming cameras. Cameras that consistently failed early compared to their cohorts were removed from analysis. 
-Manufacturing variability - how many cameras we had and their failure rates due to inexplicable software or hardware issues

### Battery type particulars

We might want to describe in more detail what battery types we used. 
- talking about high quality alkaline so dismiss zinc carbon.
-We also had some variance within the lithium batteries, including cost. 
-Rechargeable: didn’t use them. Explain why here. Will elaborate in the discussion too.

### Statistical Analysis

Survival modelling
-Have a little discussion on survival modelling in the context of equipment. 

Zac’s method


## Results

Preliminary analysis before formal statistical analysis: alkaline vs lithium (table where we compare and contrast the 2 of them). 
-Quality rating within those 2 groups. 

Consider testing some hypotheses: what effects camera battery life? Predictors might include:
-flash type, (not testing variance in cam settings e.g., # images per bursts / video ruled out)
-season
-battery type
-Region because it can vary in the extremes of temp and relative humidity etc. 

Display Items / Ideas:
-Representative profile of typical alkaline drain vs lithium (voltage vs time chart) – choose 10 sample batteries from each and fit a curve. Typical drain profiles of the 2.
-Table for the energy drain experiment 
-Table for black flash (or just in-text).
-Main field experiment: see Zac’s figures (survival profiles).
-Need an economic model in there (cost of batteries compared to other costs in atypical service budget). So, include a table of a field logistics budget (sample) and what the battery component looks like in that. RA, fuel, accom, vehicle, battery, capital cost of cameras.


## Discussion

Summary paragraph – outline main findings. 
Our results from a study working under those conditions (long-term minimal disturbance). 

Highlight here as well that in this study we present empirical information / patterns particular to our camera trap model (Cuddeback xchange 1279) that people can pick apart but encourage researchers to test this themselves.

### Battery price and quality

-Obvious price signal for quality. Discussion point. 
You pay very little for batteries in the context of the logistics of a camera survey (back of the envelope calculation of what proportion of costs go to batteries, i.e., labour and premature loss of data). ‘The false economy of cheap batteries.’ 

Rechargeable batteries, main advantage = less materially consumptive. 
But we didn’t use them. Two key issues: 1. basically need to upfront buy twice as many as you need to swap the out and, 2. inherently low volage so are likely to trigger camera failure being at the voltage margin. 

-Lowest quality lithium batteries seem to be not much better than the highest quality alkaline. 

-Talk about the failure profiles of the 2 battery types. The fact that alkaline batteries drain linearly. Lithium batteries hold voltage right to the end before dropping off. Trade-off is that it’s hard to tell when they will fail as they will just drop. 

Although disposable lithium batteries are highly recyclable (sustainability point). Could potentially use rechargeable lithium but these might be incredibly expensive so it’s not feasible (need to check this).

Battery cell variability (sometimes you get bad cells). Out of the box you can get cameras that slowly drain batteries (bad units). Sometimes however, it might be from bad batteries.

### Camera setting 

- In this section we intend to impart some camera setting wisdom – you need to take care of your batteries with the camera settings (i.e., burst v recovery time). 
If you are getting 10,000 images per month (like the study I cited at the top), something is wrong!
- Technical analysis of how different batteries perform – but the rest is advice to practitioners about camera trapping (be kind to your batteries)
- What are you trying to get out of your camera survey (what do you really need!) do you need a 30sec video etc. What is the trade-off (and there is one with SD cards and batteries, but the former is bigger and cheap, but batteries are the obvious serious consideration). 
- We might want to discuss the manufacturing variability [only if we add this to the results] including potentially how many cameras we had and their failure rates due to inexplicable software or hardware issues. Our point here is to advise researchers to buy more than they think they need! 

### Camera flash type 

Battery life affected by flash type. 
Talk briefly, what determines typical drain of cam trap? Three main elements: 
1. The power cost to write an image or video, 
2. The energy cost of the flash big diff between IR and xenon vs white LEDS, 
3. The continuous power drain of passive IR sensor. This you can’t do anything about, but the other two you can change / control.

Explain xenon flash (waiting for the capacitor to charge which can cause voltage bounce). This seems to be a feature not usually considered in camera monitoring studies (is this camera model specific i.e., do more expensive cameras have a ‘fix’ for this issue?).  

### The need for long-term monitoring

-Give a section where we talk about longer-term deployment (there is a legacy of two-week studies where battery choice doesn’t matter, but we are moving away from that) which is why batt life becomes a bigger consideration.

What is the optimal time to service? Where longer is better (staying away) but worse in the sense of larger fraction cam would have failed by the time you get there. Need to find the sweet spot to sample with minimal disturbance. 


### Recommendations / Conclusions

-Recommendation: buy the best lithium batteries you can. And think carefully about image capture schedule. 
-Provide good recommendations on relative performance of WF and IR on battery life. 
-Say something about the feasibility of moving towards long-term service times. Even with Cuddeback white flash with good batteries it’s possible to extend service schedule to 6 months (use literature to show why). IR closer to a year. Emphasising the importance of keeping human disturbance to a minimum. 
-Not lab-based conditions (which is what manufacturers report) – these are real field conditions. 
-It’s important to ask, am I satisfied that the gain I’m getting from increased number of images worth it for the battery performance?

-Why did my camera die early? Battery cell variability vs. camera manufacturing issues can be checked. If you want to know, get test kit to measure voltage and answer this question – which helps you to know whether you have a bad camera or a bad battery set. 
The cameras that died inexplicably short – you can measure the batteries and replace the ones that are bad. Low cost, solution to test !! Make sure it’s not a bad cell issue.  

-Re-emphasise: we aren’t presenting a universal result for all camera trap models and designs. But the relative perform of batteries we expect to be similar. You’ll want to collect your own to calibrate with your own data. E.g., our expectation that an obvious future direction is to transition from white flash to white LEDs as the standard.
 
### References

Newey et al (2015) Limitations of recreational camera traps for wildlife management and conservation research: A practitioner’s perspective Ambio
