# DAT610 report

Place the official DAT610 LaTeX report template here when it is available. The main LaTeX source is not present locally; the supplied PDF was used to match the draft to the existing section structure.

## HARQ methods draft

- [harq-methods-draft.tex](harq-methods-draft.tex): draft text for IV.B (HARQ Configuration), IV.C (Performance Metrics), and IV.D.2 (Evaluation 2). Copy these blocks into their respective locations; do not input the entire file consecutively because IV.D.1 already contains the SNR evaluation.
- [harq-references.bib](harq-references.bib): bibliography entries for the MathWorks HARQ example and Hoeffding's original paper. Merge these with the main bibliography. The MathWorks URL currently displays R2026b, whereas the verified project execution used R2026a.

The draft explains why retransmission cost matters, mean versus average, conditional-on-delivery metrics, and the distinction between Wilson BLER intervals and conservative Hoeffding intervals for mean retries. It documents the implemented AWGN study, not an integrated TDL experiment. It does not add results or change Person 1's text.

Before submission, review length against the course page limit, agree the uncertainty method with the group, and justify the final radio settings. The draft has not been compiled into the supplied report because its LaTeX source/template is not available here.

Planned sections: Introduction, Background, Related Work, Design and Evaluation, Results, Conclusion, References, and Appendix.

- Person 1 owns the simulation scenario and SNR experiment/results draft.
- Person 2 owns HARQ background and HARQ experiment/results draft.
- Person 3 owns the channel description and channel experiment/results draft.
- All three integrate the introduction and related work, write the conclusions together, and perform final review.

Report only verified simulations and clearly state metric definitions, settings, uncertainty, and limitations. The ownership and review schedule is in [the team plan](../docs/team-plan.md).
