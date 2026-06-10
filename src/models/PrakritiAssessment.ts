import mongoose, { Schema, Document } from 'mongoose';

export interface IPrakritiAssessment extends Document {
  userId: mongoose.Types.ObjectId;
  answers: Map<string, string>;
  doshaScores: {
    vata: number;
    pitta: number;
    kapha: number;
  };
  dominantDosha: 'Vata' | 'Pitta' | 'Kapha' | 'Vata-Pitta' | 'Pitta-Kapha' | 'Vata-Kapha' | 'Tridoshic';
  completedAt: Date;
}

const PrakritiAssessmentSchema = new Schema<IPrakritiAssessment>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    answers: {
      type: Map,
      of: String,
      required: true,
    },
    doshaScores: {
      vata: { type: Number, required: true },
      pitta: { type: Number, required: true },
      kapha: { type: Number, required: true },
    },
    dominantDosha: {
      type: String,
      enum: ['Vata', 'Pitta', 'Kapha', 'Vata-Pitta', 'Pitta-Kapha', 'Vata-Kapha', 'Tridoshic'],
      required: true,
    },
    completedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

const PrakritiAssessment = mongoose.model<IPrakritiAssessment>('PrakritiAssessment', PrakritiAssessmentSchema);
export default PrakritiAssessment;
