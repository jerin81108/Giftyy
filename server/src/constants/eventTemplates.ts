export interface IEventTemplate {
  type: string;
  label: string;
  tagline: string;
  defaultCoverUrl: string;
  defaultStory: string;
  suggestedWishlist: Array<{
    title: string;
    description: string;
    icon: string;
    amount: number;
  }>;
  isPrivateByDefault: boolean;
  isChildEvent: boolean;
}

export const EVENT_TEMPLATES: Record<string, IEventTemplate> = {
  wedding: {
    type: 'wedding',
    label: 'Wedding',
    tagline: 'Two souls, one beautiful journey',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "We're so blessed to have you in our lives. Instead of boxed gifts, help us fund our dream memories together! ✨",
    suggestedWishlist: [
      { title: 'Honeymoon in Europe', description: 'Rome, Paris & Swiss Alps romantic getaway', icon: 'plane', amount: 300000 },
      { title: 'First Home Down Payment', description: 'Building our cozy sanctuary together', icon: 'house', amount: 1000000 },
      { title: 'Trip to Japan', description: 'Tokyo street food, Kyoto temples & Mt. Fuji cherry blossoms', icon: 'mountain', amount: 250000 },
    ],
    isPrivateByDefault: false,
    isChildEvent: false,
  },
  engagement: {
    type: 'engagement',
    label: 'Engagement / Roka',
    tagline: 'A promise of forever begins today',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "Join us as we take our first step towards forever! Your presence and blessings mean the world to us.",
    suggestedWishlist: [
      { title: 'Wedding Photography Fund', description: 'Capturing our special moments forever', icon: 'gem', amount: 150000 },
      { title: 'Couple Weekend Getaway', description: 'Pre-wedding recharge trip', icon: 'plane', amount: 60000 },
    ],
    isPrivateByDefault: false,
    isChildEvent: false,
  },
  birthday: {
    type: 'birthday',
    label: 'Birthday Party',
    tagline: 'Another year bolder and wiser',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "Let's celebrate another year of life, laughter, and adventures! Come share your wishes and memories with us.",
    suggestedWishlist: [
      { title: 'Dream Tech Gadget / Laptop', description: 'Creative workstation upgrade', icon: 'gift', amount: 80000 },
      { title: 'Solo Travel Adventure', description: 'Backpacking trip to Ladakh', icon: 'mountain', amount: 45000 },
      { title: 'Books & Learning Courses', description: 'Lifelong learning fund', icon: 'charity', amount: 15000 },
    ],
    isPrivateByDefault: false,
    isChildEvent: false,
  },
  baby_shower: {
    type: 'baby_shower',
    label: 'Baby Shower / Godh Bharai / Seemantham',
    tagline: 'Welcoming our little blessing with love',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "A tiny bundle of joy is on the way! Shower our little one with your purest blessings, love, and prayers.",
    suggestedWishlist: [
      { title: 'Nursery Setup & Crib', description: 'Cozy and safe nursery furniture', icon: 'furniture', amount: 75000 },
      { title: 'Stem Cell Banking & Health Care', description: 'Long-term health protection for baby', icon: 'heart', amount: 100000 },
      { title: 'Baby Gear & Stroller Fund', description: 'Travel safety car seat and stroller', icon: 'gift', amount: 40000 },
    ],
    isPrivateByDefault: true,
    isChildEvent: true,
  },
  ear_piercing: {
    type: 'ear_piercing',
    label: 'Ear Piercing Ceremony / Karnavedha',
    tagline: 'Sacred blessings for our precious little star',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "We invite you to bless our beloved child on their traditional ear piercing ceremony (Karnavedha). Your presence and blessings are our greatest gift.",
    suggestedWishlist: [
      { title: 'Traditional Gold Earrings Fund', description: 'First gold earrings for auspicious future', icon: 'gem', amount: 35000 },
      { title: 'Higher Education Savings Deposit', description: 'Child future investment fund', icon: 'charity', amount: 100000 },
      { title: 'Ceremony Feast & Charity Meal', description: 'Sponsoring meals for orphanage in child’s name', icon: 'heart', amount: 20000 },
    ],
    isPrivateByDefault: true,
    isChildEvent: true,
  },
  coming_of_age: {
    type: 'coming_of_age',
    label: 'Coming-of-Age Ceremony / Ritu Kala / Upanayana',
    tagline: 'Celebrating the transition into adulthood and wisdom',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "Celebrating a monumental rite of passage and cultural milestone. We invite our cherished family and friends to bless our young honoree.",
    suggestedWishlist: [
      { title: 'Education & College Fund', description: 'Preparation for future academic dreams', icon: 'charity', amount: 200000 },
      { title: 'Traditional Ceremonial Attire', description: 'Traditional silks and ceremonial jewelry', icon: 'gem', amount: 40000 },
    ],
    isPrivateByDefault: true,
    isChildEvent: true,
  },
  housewarming: {
    type: 'housewarming',
    label: 'Housewarming / Griha Pravesh',
    tagline: 'New walls, new memories, warm beginnings',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "We have turned a house into our home! Come step inside, share some sweets, and help us fill our new rooms with warmth and laughter.",
    suggestedWishlist: [
      { title: 'Living Room Furniture & Sofa', description: 'Comfortable seating for hosting friends', icon: 'furniture', amount: 120000 },
      { title: 'Smart Kitchen & Appliances', description: 'Air fryer, dishwasher & coffee machine', icon: 'gift', amount: 65000 },
      { title: 'Balcony Garden & Planters', description: 'Green plants and cozy outdoor lighting', icon: 'mountain', amount: 25000 },
    ],
    isPrivateByDefault: false,
    isChildEvent: false,
  },
  graduation: {
    type: 'graduation',
    label: 'Graduation & Milestones',
    tagline: 'Caps in the air, endless horizons ahead',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "Years of hard work, sleepless nights, and determination have paid off! Celebrate this proud milestone and future endeavors with us.",
    suggestedWishlist: [
      { title: 'Post-Graduation Relocation Fund', description: 'Moving to new job city setup', icon: 'house', amount: 75000 },
      { title: 'Professional Wardrobe & Tech', description: 'Work attire and professional gear', icon: 'gift', amount: 40000 },
    ],
    isPrivateByDefault: false,
    isChildEvent: false,
  },
  anniversary: {
    type: 'anniversary',
    label: 'Wedding Anniversary',
    tagline: 'Celebrating enduring love, laughter, and milestones',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "Another year of walking hand-in-hand through life’s grand adventures. Join us to toast to past memories and many more to come!",
    suggestedWishlist: [
      { title: 'Silver / Golden Jubilee Holiday', description: 'Memorable anniversary cruise getaway', icon: 'plane', amount: 180000 },
      { title: 'Anniversary Charity Fund', description: 'Giving back to causes close to our heart', icon: 'heart', amount: 50000 },
    ],
    isPrivateByDefault: false,
    isChildEvent: false,
  },
  festival: {
    type: 'festival',
    label: 'Festival or Family Function / Puja',
    tagline: 'Togetherness, devotion, and festive joy',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "Festivals are sweetest when shared with family and dearest friends. Join our family celebrations, blessings, and feast!",
    suggestedWishlist: [
      { title: 'Community Feast & Prasad Sponsoring', description: 'Serving community meals during puja', icon: 'heart', amount: 30000 },
      { title: 'Temple Restoration / Charity Contribution', description: 'Donation in family’s name', icon: 'charity', amount: 25000 },
    ],
    isPrivateByDefault: false,
    isChildEvent: false,
  },
  custom: {
    type: 'custom',
    label: 'Custom Occasion',
    tagline: 'Celebrate life’s special moments together',
    defaultCoverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
    defaultStory: "You are warmly invited to join our special celebration. Your presence and warm wishes are all we need!",
    suggestedWishlist: [
      { title: 'Celebration Goal Fund', description: 'Contribute towards our dream celebration', icon: 'gift', amount: 50000 },
    ],
    isPrivateByDefault: false,
    isChildEvent: false,
  },
};
