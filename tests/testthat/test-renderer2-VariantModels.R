acontext("VariantModels data viz")

data(VariantModels, package = "animint2")

auc.min.error <- subset(VariantModels$auc, metric.name=="min.error")

add.filterVar <- function(df, levs){
  df$filterVar.fac <- factor(df$filterVar, levs)
  df
}
add.filterVar.fac <- function(df){
  add.filterVar(df, rev(paste(VariantModels$ranks$filterVar)))
}
add.filterVar.rev <- function(df){
  add.filterVar(df, paste(VariantModels$ranks$filterVar))
}

thresh.colors <- c("min error"="black", selected="white")
method.colors <- 
  c(knn="#8DD3C7", #green
    "#FFFFB3", #yellow
    svmRadial="#BEBADA", #pale violet
    ada="#FB8072", #pink-orange
    gbm="#FB8072", #pink-orange
    glmnet="#80B1D3", #blue
    glmnetBinDev="#80B1D3", #blue
    glmnetAcc="#80B1D3", #blue
    MQ="#FDB462", #orange
    QUAL="#B3DE69", #green
    NegFQ="#FCCDE5", #pink-violet
    DP="#D9D9D9", #grey
    rf="#BC80BD", #purple
    "#CCEBC5", #greenish yellow
    "#FFED6F") #gold
fp.fn.colors <- c(FP="skyblue",
                  fp="skyblue",
                  fn="#E41A1C",
                  FN="#E41A1C",
                  tn="white",
                  tp="grey",
                  errors="black")

first.list <- with(auc.min.error, {
  structure(as.list(threshold), names=paste0(filterVar, "_fold", test.fold))
})
first.list$test.fold <- 2

minima.df <- VariantModels$minima
minima.df$thresh.type <- "min error"

data_auc = add.filterVar.rev(VariantModels$roc)
data_auc$showVar <- with(data_auc,
                         paste0(filterVar, "_fold", test.fold))

data_roc <- VariantModels$roc
data_roc$showVar <- with(data_roc,
                         paste0(filterVar, "_fold", test.fold))

data_error <- add.filterVar.fac(VariantModels$thresholds)
data_error$clickVar <- with(data_error,
                   paste0(filterVar.fac, "_fold", test.fold))
viz <- list(
  auc=ggplot()+
    ggtitle("Performance on 3 test folds")+
    theme_bw()+
    theme_animint(height=500)+
    theme(panel.margin=grid::unit(0, "cm"))+
    facet_grid(.~metric.name, scales="free", space="fixed")+
    scale_y_discrete("method . weights")+
    scale_x_continuous("")+
    scale_color_manual(values=method.colors, guide="none")+
    scale_fill_manual("threshold", values=thresh.colors, guide="none")+
    geom_point(aes(metric.value, filterVar.fac, color=method,
                   fill=thresh.type),
               clickSelects="test.fold",
               showSelected=c("method", "thresh.type"),
               size=5,
               pch=21,
               data=add.filterVar.rev(VariantModels$auc))+
    geom_point(aes(
      error.or.Inf,
      filterVar.fac,
      key=filterVar,
      fill=thresh.type, color=method), 
      showSelected=c("test.fold", "method", "thresh.type",
                     showVar="threshold"),
               size=4,
               pch=21,
               data=data_auc),
  roc=ggplot()+
    ggtitle("ROC curves by weights and test fold")+
    scale_y_continuous("True positive rate")+
    scale_x_continuous("False positive rate",
                       breaks=c(0, 0.25, 0.5, 0.75, 1),
                       labels=c("0", "0.25", "0.5", "0.75", "1"))+
    scale_color_manual(values=method.colors)+
    coord_equal()+
    theme_bw()+
    theme_animint(width=500, height=500)+
    theme(panel.margin=grid::unit(0, "cm"))+
    facet_grid(test.fold ~ type, labeller=function(label_df){
      if(names(label_df)=="test.fold"){
        label_names <- mapply(paste, "test fold", label_df, SIMPLIFY = FALSE)
        label_context(labels = label_names)
      }else{
        lapply(label_df, paste)
      }
    })+
    geom_path(aes(FPR, TPR,
                  ##showSelected=method, #not needed!
                  group=method, tooltip=method, color=method),
              clickSelects="test.fold",
              size=5,
              data=VariantModels$roc)+
    scale_fill_manual("threshold", values=thresh.colors)+
    geom_point(aes(FPR, TPR, color=method,
                   ##showSelected=method, #not needed!
                   fill=thresh.type),
               clickSelects="test.fold",
               pch=21,
               size=4,
               data=subset(VariantModels$auc, metric.name=="auc"))+
    geom_point(aes(
      FPR, TPR,
      key=method,
      ##showSelected=method, #not needed!
      fill=thresh.type,
      color=method),
      clickSelects="test.fold",
      showSelected=c("test.fold", showVar="threshold"),
               size=3,
               pch=21,
               data=data_roc),
  error=ggplot()+
    geom_hline(aes(yintercept=min.errors),
               showSelected=c("test.fold", "thresh.type"),
               data=minima.df,
               color="grey50")+
    geom_vline(aes(xintercept=threshold),
               showSelected=c("test.fold", "thresh.type", "method"),
               data=add.filterVar.fac(auc.min.error),
               color="grey50")+
    theme_bw()+
    theme_animint(width=1800, height=500)+
    theme(panel.margin=grid::unit(0, "cm"))+
    theme(axis.text.x=element_text(angle=90))+
    facet_grid(. ~ filterVar.fac, labeller=function(label_df){
      label_df <- mapply(sub, "balanced", "b", label_df, SIMPLIFY = FALSE)
      label_df <- mapply(sub, "one", "1", label_df, SIMPLIFY = FALSE)
      label_value(label_df)
    }, scales="free", space="fixed")+
    scale_color_manual(values=fp.fn.colors)+
    geom_line(aes(threshold, error.value,
                  group=error.type, color=error.type),
              showSelected=c("test.fold", "thresh.type", "method"),
              data=add.filterVar.fac(VariantModels$error))+
    scale_fill_manual(values=method.colors, guide="none")+
    geom_tallrect(aes(
      xmin=xmin, xmax=xmax,
      fill=method),
      showSelected=c("test.fold", "thresh.type", "method"),
      clickSelects = c(clickVar="threshold"),
                  alpha=0.5,
                  color=NA,
                  data=data_error),
  selector.types=list(method="multiple", thresh.type="multiple"),
  title="3-fold CV estimates variant calling test error",
  first=first.list,
  duration=with(auc.min.error, {
    structure(as.list(rep(2000, length(threshold))),
              names=paste0(filterVar, "_fold", test.fold))
  })
)

info <- animint2HTML(viz)

viz$error+
  facet_grid(test.fold ~ filterVar.fac, labeller=function(label_df){
    if(names(label_df)=="test.fold"){
      label_names <- mapply(paste, "test fold", label_df, SIMPLIFY = FALSE)
      label_context(labels = label_names)
    }else{
      lapply(label_df, paste)
    }
  }, scales="free", space="fixed")

test_that("no duplicated rows in common data", {
  common.tsv <- file.path("animint-htmltest", "geom8_line_error_chunk_common.tsv")
  common.df <- read.table(common.tsv, comment.char="", header=TRUE)
  common.unique <- unique(common.df)
  expect_identical(common.unique, common.df)
})

test_that("error lines rendered in all panels", {
  panel.list <- getNodeSet(info$html, '//g[@class="geom8_line_error"]//g')
  computed.counts <- sapply(panel.list, function(x)length(xmlChildren(x)))
  expected.counts <- rep(3, 20)
  expect_equal(computed.counts, expected.counts)
})

xpath.vec <- 
  c('//g[@class="geom1_point_auc"]//circle',
    '//g[@class="geom2_point_auc"]//circle',
    '//g[@class="geom3_path_roc"]//path',
    '//g[@class="geom4_point_roc"]//circle',
    '//g[@class="geom5_point_roc"]//circle',
    '//g[@class="geom6_hline_error"]//line',
    '//g[@class="geom7_vline_error"]//line',
    '//g[@class="geom8_line_error"]//path',
    '//g[@class="geom9_tallrect_error"]//rect')

countGeoms <- function(html=getHTML()){
  count.vec <- c()
  for(xpath in xpath.vec){
    node.list <- getNodeSet(html, xpath)
    count.vec[[xpath]] <- length(node.list)
  }
  count.vec
}

thresh.fold2 <- subset(VariantModels$thresholds, test.fold==2)

test_that("initial geom counts", {
  expected.counts <- c(120, 20, 60, 60, 20, 20, 20, 60, nrow(thresh.fold2))
  computed.counts <- countGeoms()
  expect_equal(expected.counts, as.numeric(computed.counts))
})

clickID("plot_roc_method_variable_MQ")

thresh.fold2.not.MQ <- subset(thresh.fold2, method != "MQ")

test_that("geom counts after hiding MQ", {
  expected.counts <- c(
    114, 19, #circles in first plot
    57, 57, # path and circle in second
    19, # selected circle in second
    20, #hline
    19, #vline
    57, #path
    nrow(thresh.fold2.not.MQ)) #rect
  computed.counts <- countGeoms()
  expect_equal(expected.counts, as.numeric(computed.counts))
})

clickID("plot_roc_thresh_type_variable_min_error")

test_that("geom counts after hiding min error", {
  expected.counts <- c(
    0, 19, #circles in first plot
    57, 0, # path and circle in second
    19, # selected circle in second
    0, #hline
    0, #vline
    57, #path
    nrow(thresh.fold2.not.MQ)) #rect
  computed.counts <- countGeoms()
  expect_equal(expected.counts, as.numeric(computed.counts))
})

clickID("plot_roc_thresh_type_variable_selected")

test_that("geom counts after hiding selected", {
  expected.counts <- c(
    0, 0, #circles in first plot
    57, 0, # path and circle in second
    0, # selected circle in second
    0, #hline
    0, #vline
    0, #path
    0) #rect
  computed.counts <- countGeoms()
  expect_equal(expected.counts, as.numeric(computed.counts))
})

clickID("plot_roc_thresh_type_variable_min_error")

test_that("geom counts after showing min error", {
  expected.counts <- c(
    114, 0, #circles in first plot
    57, 57, # path and circle in second
    0, # selected circle in second
    20, #hline
    19, #vline
    0, #path
    0) #rect
  computed.counts <- countGeoms()
  expect_equal(expected.counts, as.numeric(computed.counts))
})

clickID("plot_roc_method_variable_knn")

test_that("geom counts after hiding knn", {
  expected.counts <- c(
    102, 0, #circles in first plot
    51, 51, # path and circle in second
    0, # selected circle in second
    20, #hline
    17, #vline
    0, #path
    0) #rect
  computed.counts <- countGeoms()
  expect_equal(expected.counts, as.numeric(computed.counts))
})

clickID("plot_roc_thresh_type_variable_selected")

thresh.fold2.not.knn <- subset(thresh.fold2.not.MQ, method != "knn")

test_that("geom counts after showing selected", {
  expected.counts <- c(
    102, 17, #circles in first plot
    51, 51, # path and circle in second
    17, # selected circle in second
    20, #hline
    17, #vline
    51, #path
    nrow(thresh.fold2.not.knn)) #rect
  computed.counts <- countGeoms()
  expect_equal(expected.counts, as.numeric(computed.counts))
})

clickID("plot_error_error_type_variable_errors")

test_that("geom counts after hiding errors", {
  expected.counts <- c(
    102, 17, #circles in first plot
    51, 51, # path and circle in second
    17, # selected circle in second
    20, #hline
    17, #vline
    34, #path
    nrow(thresh.fold2.not.knn)) #rect
  computed.counts <- countGeoms()
  expect_equal(expected.counts, as.numeric(computed.counts))
})

