#' Build a Mixture Hidden Markov Model
#' 
#' Function build_mhmm constructs a mixture of hidden Markov models.
#' 
#' @export
#' @useDynLib seqHMM
#' @param observations TraMineR stslist (see \code{\link{seqdef}}) containing
#'   the sequences, or a list of such objects (one for each channel).
#' @param transition_matrix A list of matrices of transition 
#'   probabilities for submodels of each cluster.
#' @param emission_matrix A list which contains matrices of emission probabilities or
#'   a list of such objects (one for each channel) for submodels of each cluster. 
#'   Note that the matrices must have dimensions m x s where m is the number of 
#'   hidden states and s is the number of unique symbols (observed states) in the 
#'   data.
#' @param initial_probs A list which contains vectors of initial state 
#'   probabilities for submodels of each cluster.
#' @param formula Covariates as an object of class \code{\link{formula}}, 
#' left side omitted.
#' @param data An optional data frame, list or environment containing the variables 
#' in the model. If not found in data, the variables are taken from 
#' \code{environment(formula)}.
#' @param beta An optional k x l matrix of regression coefficients for time-constant 
#'   covariates for mixture probabilities, where l is the number of clusters and k
#'   is the number of covariates. A logit-link is used for mixture probabilities.
#'   The first column is set to zero.
#' @param cluster_names A vector of optional names for the clusters.
#' @param state_names A list of optional labels for the hidden states.
#' @param channel_names A vector of optional names for the channels.
#' @return Object of class \code{mhmm}
#' @seealso \code{\link{fitMixHMM}} for fitting mixture Hidden Markov models.
#' 
#' @examples
#' require(TraMineR)
#' 
#' data(biofam)
#' biofam <- biofam[complete.cases(biofam[c(2:4)]),]
#' biofam <- biofam[1:500,]
#' 
#' ## Building one channel per type of event left, children or married
#' bf <- as.matrix(biofam[, 10:25])
#' children <-  bf == 4 | bf == 5 | bf == 6
#' married <- bf == 2 | bf == 3 | bf == 6
#' left <- bf == 1 | bf == 3 | bf == 5 | bf == 6 | bf == 7
#' 
#' children[children == TRUE] <- "Children"
#' children[children == FALSE] <- "Childless"
#' # Divorced parents
#' div <- bf[(rowSums(bf == 7) > 0 & rowSums(bf == 5) > 0) | 
#'             (rowSums(bf == 7) > 0 & rowSums(bf == 6) > 0),]
#' children[rownames(bf) %in% rownames(div) & bf == 7] <- "Children"
#' 
#' married[married == TRUE] <- "Married"
#' married[married == FALSE] <- "Single"
#' married[bf == 7] <- "Divorced"
#' 
#' left[left == TRUE] <- "Left home"
#' left[left == FALSE] <- "With parents"
#' # Divorced living with parents (before divorce)
#' wp <- bf[(rowSums(bf == 7) > 0 & rowSums(bf == 2) > 0 & rowSums(bf == 3) == 0 &  
#'           rowSums(bf == 5) == 0 & rowSums(bf == 6) == 0) | 
#'          (rowSums(bf == 7) > 0 & rowSums(bf == 4) > 0 & rowSums(bf == 3) == 0 &  
#'          rowSums(bf == 5) == 0 & rowSums(bf == 6) == 0),]
#' left[rownames(bf) %in% rownames(wp) & bf == 7] <- "With parents"
#' 
#' ## Building sequence objects
#' child.seq <- seqdef(children, start = 15)
#' marr.seq <- seqdef(married, start = 15)
#' left.seq <- seqdef(left, start = 15)
#' 
#' ## Starting values for emission probabilities
#' 
#' # Cluster 1
#' alphabet(child.seq) # Checking for the order of observed states
#' B1_child <- matrix(c(0.99, 0.01, # High probability for childless
#'                      0.99, 0.01,
#'                      0.99, 0.01,
#'                      0.99, 0.01), nrow = 4, ncol = 2, byrow = TRUE)
#' 
#' alphabet(marr.seq)                      
#' B1_marr <- matrix(c(0.01, 0.01, 0.98, # High probability for single
#'                     0.01, 0.01, 0.98,
#'                     0.01, 0.98, 0.01, # High probability for married
#'                     0.98, 0.01, 0.01), # High probability for divorced
#'                     nrow = 4, ncol = 3, byrow = TRUE)                   
#' 
#' alphabet(left.seq)
#' B1_left <- matrix(c(0.01, 0.99, # High probability for living with parents
#'                     0.99, 0.01, # High probability for having left home
#'                     0.99, 0.01,
#'                     0.99, 0.01), nrow = 4, ncol = 2, byrow = TRUE)
#' 
#' # Cluster 2
#' B2_child <- matrix(c(0.99, 0.01, # High probability for childless
#'                      0.99, 0.01,
#'                      0.99, 0.01,
#'                      0.01, 0.99), nrow = 4, ncol = 2, byrow = TRUE)
#'                      
#' B2_marr <- matrix(c(0.01, 0.01, 0.98, # High probability for single
#'                     0.01, 0.01, 0.98,
#'                     0.01, 0.98, 0.01, # High probability for married
#'                     0.29, 0.7, 0.01),
#'                    nrow = 4, ncol = 3, byrow = TRUE)                   
#' 
#' B2_left <- matrix(c(0.01, 0.99, # High probability for living with parents
#'                     0.99, 0.01,
#'                     0.99, 0.01,
#'                     0.99, 0.01), nrow = 4, ncol = 2, byrow = TRUE) 
#' 
#' # Cluster 3
#' B3_child <- matrix(c(0.99, 0.01, # High probability for childless
#'                      0.99, 0.01,
#'                      0.01, 0.99,
#'                      0.99, 0.01,
#'                      0.01, 0.99,
#'                      0.01, 0.99), nrow = 6, ncol = 2, byrow = TRUE)
#' 
#' B3_marr <- matrix(c(0.01, 0.01, 0.98, # High probability for single
#'                     0.01, 0.01, 0.98,
#'                     0.01, 0.01, 0.98,
#'                     0.01, 0.98, 0.01,
#'                     0.01, 0.98, 0.01, # High probability for married
#'                     0.98, 0.01, 0.01), # High probability for divorced
#'                    nrow = 6, ncol = 3, byrow = TRUE)                   
#' 
#' B3_left <- matrix(c(0.01, 0.99, # High probability for living with parents
#'                     0.99, 0.01,
#'                     0.50, 0.50,
#'                     0.01, 0.99,
#'                     0.99, 0.01,
#'                     0.99, 0.01), nrow = 6, ncol = 2, byrow = TRUE) 
#' 
#' # Initial values for transition matrices
#' A1 <- matrix(c(0.8,   0.16, 0.03, 0.01,
#'                  0,    0.9, 0.07, 0.03, 
#'                  0,      0,  0.9,  0.1, 
#'                  0,      0,    0,    1), 
#'              nrow = 4, ncol = 4, byrow = TRUE)
#' 
#' A2 <- matrix(c(0.8, 0.10, 0.05,  0.03, 0.01, 0.01,
#'                  0,  0.7,  0.1,   0.1, 0.05, 0.05,
#'                  0,    0, 0.85,  0.01,  0.1, 0.04,
#'                  0,    0,    0,   0.9, 0.05, 0.05,
#'                  0,    0,    0,     0,  0.9,  0.1,
#'                  0,    0,    0,     0,    0,    1), 
#'              nrow = 6, ncol = 6, byrow = TRUE)
#' 
#' # Initial values for initial state probabilities 
#' initial_probs1 <- c(0.9, 0.07, 0.02, 0.01)
#' initial_probs2 <- c(0.9, 0.04, 0.03, 0.01, 0.01, 0.01)
#' 
#' # Creating covariate swiss
#' biofam$swiss <- biofam$nat_1_02 == "Switzerland"
#' biofam$swiss[biofam$swiss == TRUE] <- "Swiss"
#' biofam$swiss[biofam$swiss == FALSE] <- "Other"
#' 
#' # Build mixture HMM
#' bMHMM <- buildMixHMM(
#'   observations = list(child.seq, marr.seq, left.seq),
#'   transition_matrix = list(A1,A1,A2),
#'   emission_matrix = list(list(B1_child, B1_marr, B1_left),
#'                         list(B2_child, B2_marr, B2_left), 
#'                         list(B3_child, B3_marr, B3_left)),
#'   initial_probs = list(initial_probs1, initial_probs1, initial_probs2),
#'   formula = ~ sex * birthyr + sex * swiss, data = biofam,
#'   cluster_names = c("Cluster 1", "Cluster 2", "Cluster 3"),
#'   channel_names = c("Parenthood", "Marriage", "Left home")
#'   )
#'                     
build_mhmm <- 
  function(observations,transition_matrix,emission_matrix,initial_probs, 
           formula, data, beta, cluster_names=NULL, state_names=NULL, channel_names=NULL){
    
    number_of_clusters<-length(transition_matrix)
    if(length(emission_matrix)!=number_of_clusters || length(initial_probs)!=number_of_clusters)
      stop("Unequal lengths of transition_matrix, emission_matrix and initial_probs.")
    
    if(is.null(cluster_names)){
      cluster_names <- paste("Cluster", 1:number_of_clusters)
    }else if(length(cluster_names)!=number_of_clusters){
      warning("The length of argument cluster_names does not match the number of clusters. Names were not used.")
      cluster_names <- paste("Cluster", 1:number_of_clusters)
    }
      
    model <- vector("list", length = number_of_clusters)
    
    # States
    number_of_states <- unlist(lapply(transition_matrix,nrow))
    
    if(any(rep(number_of_states,each=2)!=unlist(lapply(transition_matrix,dim))))
      stop("Transition matrices must be square matrices.")
    
    if(is.null(state_names)){
      state_names <- vector("list", number_of_clusters)
      for(m in 1:number_of_clusters){
        state_names[[m]] <- as.character(1:number_of_states[m])
      }
    }
    
    if(!all(1==unlist(sapply(transition_matrix,rowSums))))
      stop("Transition probabilities in transition_matrix do not sum to one.")
    
    if(!all(1==unlist(sapply(initial_probs,sum))))
      stop("Initial state probabilities do not sum to one.")

    for(i in 1:number_of_clusters){

      dimnames(transition_matrix[[i]]) <- list(from=state_names[[i]],to=state_names[[i]])
      # Single channel but emission_matrix is list of lists  
      if(is.list(emission_matrix[[i]]) && length(emission_matrix[[i]])==1)   
        emission_matrix[[i]] <- emission_matrix[[i]][[1]]
    }
    
    
    
    
    # Single channel but observations is a list
    if(is.list(observations) && !inherits(observations, "stslist") && length(observations)==1)
      observations <- observations[[1]]
    
    number_of_channels <- ifelse(is.list(emission_matrix[[1]]),length(emission_matrix[[1]]),1)
    
    if(number_of_channels>1 && any(sapply(emission_matrix,length)!=number_of_channels))
      stop("Number of channels defined by emission matrices differ from each other.")
    
    if(number_of_channels>1){
      if(length(observations)!=number_of_channels){
        stop("Number of channels defined by emission_matrix differs from one defined by observations.")
      }
      
      
      number_of_sequences<-nrow(observations[[1]])
      length_of_sequences<-ncol(observations[[1]])
      

      symbol_names<-lapply(observations,alphabet)
      number_of_symbols<-sapply(symbol_names,length)
      for(i in 1:number_of_clusters){
        if(any(lapply(emission_matrix[[i]],nrow)!=number_of_states[i]))
          stop(paste("Number of rows in emission_matrix of cluster", i, "is not equal to the number of states."))
        
        if(any(number_of_symbols!=sapply(emission_matrix[[i]],ncol)))
          stop(paste("Number of columns in emission_matrix of cluster", i, "is not equal to the number of symbols."))
        if(!isTRUE(all.equal(c(sapply(emission_matrix[[i]],rowSums)),
                             rep(1,number_of_channels*number_of_states[i]),check.attributes=FALSE)))
          stop(paste("Emission probabilities in emission_matrix of cluster", i, "do not sum to one."))
        if(is.null(channel_names)){
          channel_names<-as.character(1:number_of_channels)
        }else if(length(channel_names)!=number_of_channels){
          warning("The length of argument channel_names does not match the number of channels. Names were not used.")
          channel_names<-as.character(1:number_of_channels)
        }
        for(j in 1:number_of_channels)
          dimnames(emission_matrix[[i]][[j]])<-list(state_names=state_names[[i]],symbol_names=symbol_names[[j]])
        names(emission_matrix[[i]])<-channel_names
      }
    } else {
      number_of_channels <- 1
      channel_names<-NULL
      number_of_sequences<-nrow(observations)
      length_of_sequences<-ncol(observations)
      symbol_names<-alphabet(observations)
      number_of_symbols<-length(symbol_names)
      
      for(i in 1:number_of_clusters){
        if(number_of_states[i]!=dim(emission_matrix[[i]])[1])
          stop("Number of rows in emission_matrix is not equal to the number of states.")
        if(number_of_symbols!=dim(emission_matrix[[i]])[2])
          stop("Number of columns in emission_matrix is not equal to the number of symbols.")
        if(!isTRUE(all.equal(rep(1,number_of_states[i]),rowSums(emission_matrix[[i]]),check.attributes=FALSE)))
          stop("Emission probabilities in emission_matrix do not sum to one.")
        dimnames(emission_matrix[[i]])<-list(state_names=state_names[[i]],symbol_names=symbol_names)
      }
      
    }
    
    
    if(!missing(formula)){
      if(inherits(formula, "formula")){
      X <- model.matrix(formula, data) #[,-1,drop=FALSE]
      if(nrow(X)!=number_of_sequences)
        stop("Number of subjects in data for covariates does not match the number of subjects in the sequence data.")
      number_of_covariates<-ncol(X)
      }else{
        stop("Object given for argument formula is not of class formula.")
      }
      if(missing(beta)){
        beta<-matrix(0,number_of_covariates,number_of_clusters)
      } else {
        if(ncol(beta)!=number_of_clusters | nrow(beta)!=number_of_covariates)
          stop("Wrong dimensions of beta.")
        beta[,1]<-0
      }       
    } else { #Just intercept
      number_of_covariates <-1
      X <- matrix(1,nrow=number_of_sequences)
      beta <- matrix(0,1,number_of_clusters)        
    }
    
    rownames(beta) <- colnames(X)
    colnames(beta) <- cluster_names
    
    names(transition_matrix) <- names(emission_matrix) <- names(initial_probs) <- cluster_names
    
    pr <- exp(X%*%beta)
    cluster_probabilities <- pr/rowSums(pr)
    
    model<-list(observations=observations, transition_matrix=transition_matrix,
                emission_matrix=emission_matrix, initial_probs=initial_probs,
                beta=beta, X=X, cluster_names=cluster_names, state_names=state_names, 
                symbol_names=symbol_names, channel_names=channel_names, 
                length_of_sequences=length_of_sequences,
                number_of_sequences=number_of_sequences, number_of_clusters=number_of_clusters,
                number_of_symbols=number_of_symbols, number_of_states=number_of_states,
                number_of_channels=number_of_channels,
                number_of_covariates=number_of_covariates, 
                cluster_probabilities=cluster_probabilities)
    class(model)<-"mhmm"
    model
  }