import { Response } from 'express';
import PrakritiAssessment from '../models/PrakritiAssessment';
import User from '../models/User';
import { catchAsync } from '../utils/catchAsync';
import { AuthRequest } from '../middlewares/auth.middleware';
import { AppError } from '../utils/AppError';

// Static Prakriti questions list
const PRAKRITI_QUESTIONS = [
  {
    id: 'frame',
    text: 'What is your physical body frame/structure?',
    options: [
      { key: 'vata', text: 'Thin, bony, very tall or short, finds it hard to gain weight' },
      { key: 'pitta', text: 'Medium build, muscular, maintains weight easily' },
      { key: 'kapha', text: 'Large build, stout, gains weight easily, struggles to lose it' }
    ]
  },
  {
    id: 'skin',
    text: 'How would you describe your skin?',
    options: [
      { key: 'vata', text: 'Dry, rough, thin, cool, prone to cracking' },
      { key: 'pitta', text: 'Warm, reddish, sensitive, prone to acne/freckles' },
      { key: 'kapha', text: 'Thick, oily, cool, smooth, soft, fair complexion' }
    ]
  },
  {
    id: 'hair',
    text: 'What is the natural state of your hair?',
    options: [
      { key: 'vata', text: 'Dry, brittle, curly, coarse, frizzy' },
      { key: 'pitta', text: 'Fine, soft, straight, prone to early greying or thinning' },
      { key: 'kapha', text: 'Thick, abundant, oily, shiny, wavy' }
    ]
  },
  {
    id: 'digestion',
    text: 'How is your digestion and appetite?',
    options: [
      { key: 'vata', text: 'Irregular, variable, prone to bloating/gas/constipation' },
      { key: 'pitta', text: 'Strong, intense, gets angry/irritable when hungry' },
      { key: 'kapha', text: 'Slow, steady, can easily skip meals, heavy feeling after eating' }
    ]
  },
  {
    id: 'sleep',
    text: 'What are your sleep habits?',
    options: [
      { key: 'vata', text: 'Light, interrupted, sleeps fewer hours, prone to insomnia' },
      { key: 'pitta', text: 'Moderate, sound, falls asleep easily but wakes warm' },
      { key: 'kapha', text: 'Deep, heavy, sleeps long hours, hard to wake up' }
    ]
  },
  {
    id: 'weather',
    text: 'What weather/climate do you prefer?',
    options: [
      { key: 'vata', text: 'Dislikes cold, dry, wind; loves warm, sunny weather' },
      { key: 'pitta', text: 'Dislikes hot weather, prefers air conditioning/cold drinks' },
      { key: 'kapha', text: 'Dislikes damp, humid, cold; prefers dry, warm weather' }
    ]
  },
  {
    id: 'mind',
    text: 'How does your mind process information?',
    options: [
      { key: 'vata', text: 'Quick to learn but quick to forget, creative, restless' },
      { key: 'pitta', text: 'Sharp, focused, logical, goal-oriented, impatient' },
      { key: 'kapha', text: 'Slow to learn but has excellent long-term memory, calm' }
    ]
  },
  {
    id: 'speech',
    text: 'What is your style of speaking?',
    options: [
      { key: 'vata', text: 'Fast, talkative, wanders off-topic easily' },
      { key: 'pitta', text: 'Clear, direct, convincing, loves debates/arguments' },
      { key: 'kapha', text: 'Slow, melodious, quiet, speaks only when necessary' }
    ]
  },
  {
    id: 'activity',
    text: 'How would you describe your activity level?',
    options: [
      { key: 'vata', text: 'Hyperactive, always on the go, gets tired easily' },
      { key: 'pitta', text: 'Energetic, purposeful, highly competitive' },
      { key: 'kapha', text: 'Slow-paced, relaxed, high physical stamina' }
    ]
  },
  {
    id: 'stress',
    text: 'How do you typically react to stress?',
    options: [
      { key: 'vata', text: 'Anxiety, worry, fear, overthinking' },
      { key: 'pitta', text: 'Anger, irritability, frustration' },
      { key: 'kapha', text: 'Calm, silent, stubborn, avoids confrontation' }
    ]
  }
];

// Dosha descriptions and dietary advice
const DOSHA_PROFILES: Record<string, { title: string; description: string; advice: string }> = {
  'Vata': {
    title: 'Vata Dominant (Air & Ether)',
    description: 'You are energetic, creative, and lively. You are likely to have a lean physique and be quick on your feet. When out of balance, you may experience anxiety, dry skin, and irregular digestion.',
    advice: 'Favor warm, cooked, nourishing foods (stews, soups, cooked grains). Avoid cold, raw, and dry foods. Keep a regular routine.'
  },
  'Pitta': {
    title: 'Pitta Dominant (Fire & Water)',
    description: 'You are highly focused, sharp-witted, and passionate. You likely have a moderate athletic build and strong digestion. When out of balance, you may become irritable, suffer from heartburn, or get skin rashes.',
    advice: 'Favor cooling, refreshing foods (sweet fruits, leafy greens, cucumber, coconut). Avoid spicy, fried, acidic, and fermented foods.'
  },
  'Kapha': {
    title: 'Kapha Dominant (Earth & Water)',
    description: 'You are calm, stable, caring, and strong. You likely have a sturdy build, thick hair, and great stamina. When out of balance, you may experience sluggishness, weight gain, and sinus congestion.',
    advice: 'Favor warm, light, spicy, and stimulating foods. Minimize sweet, salty, heavy, and oily foods.'
  },
  'Vata-Pitta': {
    title: 'Vata-Pitta Dual Constitution',
    description: 'You share traits of both Vata (creativity, quick mind) and Pitta (focus, strong digestion). You are energetic and assertive but prone to quick burnouts and digestive acidity.',
    advice: 'Focus on nourishing, mildly spiced cooked meals. Keep warm but avoid excessively hot or spicy foods.'
  },
  'Pitta-Kapha': {
    title: 'Pitta-Kapha Dual Constitution',
    description: 'You combine the focus and drive of Pitta with the stability and endurance of Kapha. You have a strong, robust constitution. You can be stubborn but are highly dependable.',
    advice: 'Favor warm, lightly spiced, and low-fat foods. Balance cooling Pitta foods with light, dry Kapha foods.'
  },
  'Vata-Kapha': {
    title: 'Vata-Kapha Dual Constitution',
    description: 'You combine Vata\'s quick mind and creative spark with Kapha\'s steady, calm nature. You may struggle with digestion and cold sensitivity.',
    advice: 'Focus on warm, cooked, lightly spiced, and dry foods. Avoid cold foods and drinks entirely.'
  },
  'Tridoshic': {
    title: 'Tridoshic (Equal Vata, Pitta, & Kapha)',
    description: 'All three doshas are in near-perfect equilibrium in your body. This is a rare constitution offering great health and adaptability.',
    advice: 'Maintain a balanced diet that adjusts to the seasons. Avoid over-indulging in any single food category.'
  }
};

/**
 * GET /prakriti/questions
 * Get quiz questions
 */
export const getQuestions = catchAsync(async (req: AuthRequest, res: Response) => {
  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: PRAKRITI_QUESTIONS,
  });
});

/**
 * POST /prakriti/submit
 * Evaluate quiz answers and save results
 */
export const submitAssessment = catchAsync(async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    throw new AppError('User not authenticated', 401);
  }

  const { answers } = req.body;

  if (!answers || typeof answers !== 'object') {
    throw new AppError('Quiz answers are required and must be an object', 400);
  }

  // Count scores
  let vata = 0;
  let pitta = 0;
  let kapha = 0;

  for (const qId in answers) {
    const val = String(answers[qId]).toLowerCase();
    if (val === 'vata') vata++;
    else if (val === 'pitta') pitta++;
    else if (val === 'kapha') kapha++;
  }

  const total = vata + pitta + kapha;
  if (total === 0) {
    throw new AppError('No valid answers provided', 400);
  }

  // Determine dominant Dosha
  let dominantDosha: 'Vata' | 'Pitta' | 'Kapha' | 'Vata-Pitta' | 'Pitta-Kapha' | 'Vata-Kapha' | 'Tridoshic' = 'Tridoshic';

  // Calculate scores
  const vataPct = vata / total;
  const pittaPct = pitta / total;
  const kaphaPct = kapha / total;

  const thresholdDual = 0.15; // Within 15% is a dual tie

  const maxVal = Math.max(vataPct, pittaPct, kaphaPct);

  // Check for absolute close-three tie (Tridoshic)
  if (
    Math.abs(vataPct - pittaPct) <= thresholdDual &&
    Math.abs(pittaPct - kaphaPct) <= thresholdDual &&
    Math.abs(vataPct - kaphaPct) <= thresholdDual
  ) {
    dominantDosha = 'Tridoshic';
  } else {
    // Find ties/duals between top 2
    const sorted = [
      { name: 'Vata', val: vataPct },
      { name: 'Pitta', val: pittaPct },
      { name: 'Kapha', val: kaphaPct }
    ].sort((a, b) => b.val - a.val);

    if (sorted[0].val - sorted[1].val <= thresholdDual) {
      // It's a dual Dosha
      const dualName = `${sorted[0].name}-${sorted[1].name}`;
      if (dualName === 'Vata-Pitta' || dualName === 'Pitta-Vata') dominantDosha = 'Vata-Pitta';
      else if (dualName === 'Pitta-Kapha' || dualName === 'Kapha-Pitta') dominantDosha = 'Pitta-Kapha';
      else dominantDosha = 'Vata-Kapha';
    } else {
      // Single dominant
      dominantDosha = sorted[0].name as 'Vata' | 'Pitta' | 'Kapha';
    }
  }

  // Save assessment record
  const assessment = await PrakritiAssessment.create({
    userId: req.user.userId,
    answers,
    doshaScores: { vata, pitta, kapha },
    dominantDosha,
  });

  // Update user profile
  await User.findByIdAndUpdate(req.user.userId, { dominantDosha });

  const profile = DOSHA_PROFILES[dominantDosha];

  res.status(200).json({
    statusCode: 200,
    status: 'success',
    data: {
      assessment,
      dominantDosha,
      scores: {
        vata,
        pitta,
        kapha,
        vataPct: Math.round(vataPct * 100),
        pittaPct: Math.round(pittaPct * 100),
        kaphaPct: Math.round(kaphaPct * 100)
      },
      profile,
    }
  });
});
