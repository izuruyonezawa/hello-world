// Create simple data to explore binreg, rd
// createsimpledata.do
// IW 4dec2024



// 1. TREATMENT ONLY
clear
input randtrt outcome n
0 0 0
0 1 100 
1 0 10
1 1 90
end 
l
* treatment is a perfect predictor

// simple analysis methods
cs outcome randtrt [fw=n]
reg outcome randtrt [fw=n]

// binreg analyses
* IRLS without asis refuses to estimate
binreg outcome randtrt [fw=n], rd 
* IRLS with asis gets it right
binreg outcome randtrt [fw=n], rd asis
* ML without asis also refuses to estimate
binreg outcome randtrt [fw=n], rd ml
* ML with asis fails to converge
binreg outcome randtrt [fw=n], rd ml asis iter(20)

capture noisily glm outcome randtrt [fw=n], family(binomial) link(identity) nolog 


// 2. TREATMENT AND COVARIATE
clear
input cov randtrt ntot n1
0 0 100 90
0 1 100 94
1 0 100 100
1 1 100 100
end 
gen n0 = ntot - n1
drop ntot
reshape long n, i(cov randtrt) j(outcome)
l
* cov is a perfect predictor

* display data
table outcome (cov randtrt) [fw=n]

// simple unadjusted analysis
cs outcome randtrt [fw=n]
/*
predict pv
sum pv if randtrt == 0 & cov == 0
sum pv if randtrt == 1 & cov == 0
sum pv if randtrt == 0 & cov == 1
sum pv if randtrt == 1 & cov == 1
*/

// simple adjusted analysis
reg outcome randtrt cov [fw=n]
predict pv1
sum pv1 if randtrt == 0 & cov == 0
sum pv1 if randtrt == 1 & cov == 0
sum pv1 if randtrt == 0 & cov == 1
sum pv1 if randtrt == 1 & cov == 1


// binreg analyses
* IRLS wrongly drops a subgroup
binreg outcome randtrt cov [fw=n], rd 
predict pv2
sum pv2 if randtrt == 0 & cov == 0
sum pv2 if randtrt == 1 & cov == 0
sum pv2 if randtrt == 0 & cov == 1
sum pv2 if randtrt == 1 & cov == 1

* IRLS with asis keeps the subgroup but still gets it wrong
binreg outcome randtrt cov [fw=n], rd asis
predict pv3
sum pv3 if randtrt == 0 & cov == 0
sum pv3 if randtrt == 1 & cov == 0
sum pv3 if randtrt == 0 & cov == 1
sum pv3 if randtrt == 1 & cov == 1

* ML similarly drops the subgroup
binreg outcome randtrt cov [fw=n], rd ml
predict pv4
sum pv4 if randtrt == 0 & cov == 0
sum pv4 if randtrt == 1 & cov == 0
sum pv4 if randtrt == 0 & cov == 1
sum pv4 if randtrt == 1 & cov == 1


* ML with asis goes crazy (explanation below)
binreg outcome randtrt cov [fw=n], rd ml asis iter(20) 
/* From Stata manual: 
	As suggested by Wacholder, at each iteration,
	fitted probabilities are checked for range conditions (and put back in range if necessary). For example,
	if the identity link results in a fitted probability that is smaller than 1e–4, the probability is replaced
	with 1e–4 before the link function is calculated.
This explains why results are insensitive to beta for cov.
*/



* Standardisation with asis
logistic outcome i.randtrt i.cov [fw=n]
margins r.randtrt
predict pv5
sum pv5 if randtrt == 0 & cov == 0
sum pv5 if randtrt == 1 & cov == 0
sum pv5 if randtrt == 0 & cov == 1
sum pv5 if randtrt == 1 & cov == 1

