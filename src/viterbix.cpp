//Viterbi algorithm for MHMM
#include "seqHMM.h"

// [[Rcpp::export]]

List viterbix(const arma::mat& transition, const arma::cube& emission,
    const arma::vec& init, const arma::ucube& obs, const arma::mat& coef, const arma::mat& X,
    const arma::uvec& numberOfStates) {

  arma::umat q(obs.n_slices, obs.n_cols);
  arma::vec logp(obs.n_slices);


  arma::mat lweights = exp(X * coef).t();
  lweights.each_row() /= sum(lweights, 0);
  lweights = log(lweights);

  for (unsigned int k = 0; k < obs.n_slices; k++) {
    arma::mat delta(emission.n_rows, obs.n_cols);
    arma::umat phi(emission.n_rows, obs.n_cols);
    
    delta.col(0) = init + reparma(lweights.col(k), numberOfStates);
    for (unsigned int r = 0; r < emission.n_slices; r++) {
      delta.col(0) += emission.slice(r).col(obs(r, 0, k));
    }

    phi.col(0).zeros();

    for (unsigned int t = 1; t < obs.n_cols; t++) {
      for (unsigned int j = 0; j < emission.n_rows; j++) {
        (delta.col(t - 1) + transition.col(j)).max(phi(j, t));
        delta(j, t) = delta(phi(j, t), t - 1) + transition(phi(j, t), j);
        for (unsigned int r = 0; r < emission.n_slices; r++) {
          delta(j, t) += emission(j, obs(r, t, k), r);
        }
      }
    }

    //delta.col(obs.n_cols - 1).max(q(k, obs.n_cols - 1));
    q(k, obs.n_cols - 1) = delta.col(obs.n_cols - 1).index_max();
    for (int t = (obs.n_cols - 2); t >= 0; t--) {
      q(k, t) = phi(q(k, t + 1), t + 1);
    }
    logp(k) = delta.col(obs.n_cols - 1).max();
  }

  return List::create(Named("q") = wrap(q), Named("logp") = wrap(logp));
}
