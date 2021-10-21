/* */
/* https://www.oracle.com/webfolder/technetwork/tutorials/obe/db/sqldev/r40/sqldev4.0_GS/sqldev4.0_GS.html#section6 */

/* Demographics */
SELECT subjectkey, interview_age, interview_date, sex, demo_ed_v2,
    demo_race_a_p___10, demo_race_a_p___11, demo_race_a_p___12, demo_race_a_p___13, demo_race_a_p___14, demo_race_a_p___15, demo_race_a_p___16,
    demo_race_a_p___17, demo_race_a_p___18, demo_race_a_p___19, demo_race_a_p___20, demo_race_a_p___21, demo_race_a_p___22, demo_race_a_p___23,
    demo_race_a_p___24, demo_race_a_p___25, demo_race_a_p___77, demo_race_a_p___99, demo_ethn_v2,
    demo_origin_v2, demo_years_us_v2, 
    demo_prnt_ed_v2, demo_prnt_empl_v2, demo_prnt_empl_time,
    demo_prnt_prtnr_v2, demo_prtnr_ed_v2, demo_prtnr_empl_v2, demo_prtnr_empl_time,
    demo_comb_income_v2, demo_roster_v2
FROM pdem02;

/* NIH toolbox */
SELECT subjectkey,
    nihtbx_picvocab_date, nihtbx_picvocab_language, nihtbx_picvocab_uncorrected, nihtbx_picvocab_agecorrected, nihtbx_picvocab_v,
    nihtbx_reading_date, nihtbx_reading_language, nihtbx_reading_uncorrected, 	nihtbx_reading_agecorrected, nihtbx_reading_v
FROM abcd_tbss01;
    

/* Pilot Part 1 */
/* MRI info */
SELECT abcd_mri01.subjectkey,
    abcd_mri01.abcd_mri01_id, abcd_mri01.mri_info_manufacturersmn, 
    abcd_mri01.mri_info_deviceserialnumber, abcd_mri01.mri_info_magneticfieldstrength, abcd_mri01.mri_info_softwareversion,
    abcd_mri01.mri_info_studydate
FROM abcd_mri01;
/* Pearson Scores */
SELECT abcd_ps01.subjectkey,
    abcd_ps01.pea_assessmentdate, abcd_ps01.pea_wiscv_tss
FROM abcd_ps01;
/* RA notes */
SELECT abcd_ra01.subjectkey,
    abcd_ra01.ra_scan_check_list_sspc
FROM abcd_ra01;
/* Screener questions */
SELECT abcd_screen01.subjectkey,
    abcd_screen01.scrn_cpalsy, abcd_screen01.scrn_tumor, abcd_screen01.scrn_stroke, abcd_screen01.scrn_aneurysm, abcd_screen01.scrn_hemorrhage, 
    abcd_screen01.scrn_hemotoma, abcd_screen01.scrn_medcond_other, abcd_screen01.scrn_epls, abcd_screen01.scrn_seizure, abcd_screen01.scrn_con_excl,
    abcd_screen01.scrn_schiz, abcd_screen01.scrn_asd, abcd_screen01.scrn_psych_excl, abcd_screen01.scrn_speakeng
FROM abcd_screen01;
/* Twin info */
SELECT acspsw03.subjectkey,
    acspsw03.race_ethnicity, acspsw03.rel_group_id, acspsw03.rel_ingroup_order, acspsw03.rel_family_id, acspsw03.genetic_af_european
FROM acspsw03;


/* Pilot Part 2 */
/* MR Findings */
SELECT abcd_mrfindings01.subjectkey,
    abcd_mrfindings01.mrif_score, abcd_mrfindings01.mrif_hydrocephalus, abcd_mrfindings01.mrif_herniation
FROM abcd_mrfindings01;
/* Freesurfer QC */
SELECT freesqc01.subjectkey,
    freesqc01.fsqc_qc, freesqc01.fsqc_qu_motion, freesqc01.fsqc_qu_pialover
FROM freesqc01;


/* Pilot Part 3 */
SELECT abcd_mx01.subjectkey,
    /* Medical History */
    abcd_mx01.medhx_2c, abcd_mx01.medhx_2f, abcd_mx01.medhx_2h, abcd_mx01.medhx_2m, abcd_mx01.medhx_6p, abcd_mx01.medhx_6p_notes
FROM abcd_mx01;


/* Count frequency */
SELECT pea_wiscv_tss, COUNT(*) AS Frequency 
FROM abcd_ps01
GROUP BY pea_wiscv_tss
ORDER BY COUNT(*) DESC;

SELECT COUNT(subjectkey) FROM abcd_ps01;

/* Query w/selections */
/* Pilot Part 1 */
SELECT abcd_mri01.subjectkey, 
    abcd_ps01.subjectkey,
    /* MRI info */
    abcd_mri01.abcd_mri01_id, abcd_mri01.mri_info_manufacturersmn, 
    abcd_mri01.mri_info_deviceserialnumber, abcd_mri01.mri_info_magneticfieldstrength, abcd_mri01.mri_info_softwareversion,
    abcd_mri01.mri_info_studydate,
    /* Pearson Scores */
    abcd_ps01.pea_assessmentdate, abcd_ps01.pea_wiscv_tss
FROM abcd_mri01, abcd_ps01
WHERE abcd_mri01.subjectkey=abcd_ps01.subjectkey
    AND mri_info_manufacturersmn = 'Prisma_fit'
    AND mri_info_deviceserialnumber = 'HASH96a0c182' /* Same machine */
    AND pea_wiscv_tss > 4 /* Normal cognition */;