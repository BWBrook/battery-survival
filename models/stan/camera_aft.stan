// Matched AFT sensitivity: log-time errors and optional normal camera effect.
// family_id 1: Weibull; 2: loglogistic. sigma is survreg's AFT scale.
data {
  int<lower=1> N;
  int<lower=1> P;
  int<lower=1> B;
  int<lower=1> J;
  matrix[N, P] X;
  vector[N] log_time;
  array[N] int<lower=0, upper=1> event;
  array[N] int<lower=1, upper=B> brand;
  array[N] int<lower=1, upper=J> camera;
  int<lower=1, upper=2> family_id;
  int<lower=0, upper=1> use_camera;
  real intercept_mean;
  real<lower=0> intercept_sd;
  real<lower=0> beta_sd;
  real log_scale_mean;
  real<lower=0> log_scale_sd;
  real<lower=0> camera_sd_scale;
}
parameters {
  real alpha;
  vector[P] beta;
  vector[B] log_sigma;
  vector[use_camera * J] z_camera;
  vector<lower=0>[use_camera] tau;
}
transformed parameters {
  vector[B] sigma = exp(log_sigma);
}
model {
  vector[N] mu = alpha + X * beta;
  if (use_camera == 1) {
    for (n in 1:N) mu[n] += tau[1] * z_camera[camera[n]];
  }
  alpha ~ normal(intercept_mean, intercept_sd);
  beta ~ normal(0, beta_sd);
  log_sigma ~ normal(log_scale_mean, log_scale_sd);
  if (use_camera == 1) {
    z_camera ~ std_normal();
    tau ~ normal(0, camera_sd_scale);
  }
  for (n in 1:N) {
    real z = (log_time[n] - mu[n]) / sigma[brand[n]];
    if (family_id == 1) {
      if (event[n] == 1)
        target += -log_sigma[brand[n]] + z - exp(z) - log_time[n];
      else
        target += -exp(z);
    } else {
      if (event[n] == 1)
        target += logistic_lpdf(log_time[n] | mu[n], sigma[brand[n]])
                  - log_time[n];
      else
        target += logistic_lccdf(log_time[n] | mu[n], sigma[brand[n]]);
    }
  }
}
generated quantities {
  real log_lik_total = 0;
  for (n in 1:N) {
    real eta = alpha + X[n] * beta;
    if (use_camera == 1) eta += tau[1] * z_camera[camera[n]];
    if (family_id == 1) {
      if (event[n] == 1)
        log_lik_total += weibull_lpdf(exp(log_time[n]) | 1 / sigma[brand[n]], exp(eta));
      else
        log_lik_total += weibull_lccdf(exp(log_time[n]) | 1 / sigma[brand[n]], exp(eta));
    } else {
      if (event[n] == 1)
        log_lik_total += logistic_lpdf(log_time[n] | eta, sigma[brand[n]]) - log_time[n];
      else
        log_lik_total += logistic_lccdf(log_time[n] | eta, sigma[brand[n]]);
    }
  }
}
