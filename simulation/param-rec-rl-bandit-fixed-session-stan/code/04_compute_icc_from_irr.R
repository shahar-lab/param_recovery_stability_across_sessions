# reads: artifacts/true_parameters.rds
# writes: artifacts/icc_from_irr.rds

#### COMPUTE ICC FROM IRR ####
# Sample ICC of the drawn true log beta values (before any fitting).

true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))

df_wide <- true_parameters |>
  select(subject_id, session_id, log_beta) |>
  pivot_wider(
    names_from   = session_id,
    values_from  = log_beta,
    names_prefix = "session_"
  ) |>
  select(-subject_id)

icc_agreement_irr   <- icc(df_wide, model = "twoway", type = "agreement",   unit = "single")
icc_consistency_irr <- icc(df_wide, model = "twoway", type = "consistency", unit = "single")

icc_from_irr <- list(
  ICC_agreement   = icc_agreement_irr$value,
  ICC_consistency = icc_consistency_irr$value
)

cat("\nirr::icc on true log beta (twoway, single unit)\n")
print(icc_agreement_irr)
print(icc_consistency_irr)
cat(
  sprintf(
    "\nSaved values: ICC_agreement = %.4f, ICC_consistency = %.4f\n",
    icc_from_irr$ICC_agreement,
    icc_from_irr$ICC_consistency
  )
)

saveRDS(icc_from_irr, file.path(artifacts_dir, "icc_from_irr.rds"))
