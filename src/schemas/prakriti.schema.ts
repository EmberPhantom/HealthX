import { z } from 'zod';

export const submitAssessmentSchema = z.object({
  answers: z.record(z.string(), z.union([z.string(), z.number()])).refine((val) => Object.keys(val).length > 0, {
    message: 'Answers must not be empty',
  }),
});

export type SubmitAssessmentInput = z.infer<typeof submitAssessmentSchema>;
