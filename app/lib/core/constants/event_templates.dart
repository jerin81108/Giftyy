class EventTemplateWishlistGoal {
  final String title;
  final String description;
  final String icon;
  final int amount;

  const EventTemplateWishlistGoal({
    required this.title,
    required this.description,
    required this.icon,
    required this.amount,
  });
}

class EventTemplate {
  final String type;
  final String label;
  final String tagline;
  final String defaultCoverUrl;
  final String defaultStory;
  final List<EventTemplateWishlistGoal> suggestedWishlist;
  final bool isPrivateByDefault;
  final bool isChildEvent;

  const EventTemplate({
    required this.type,
    required this.label,
    required this.tagline,
    required this.defaultCoverUrl,
    required this.defaultStory,
    required this.suggestedWishlist,
    this.isPrivateByDefault = false,
    this.isChildEvent = false,
  });
}

class EventTemplates {
  static const List<EventTemplate> all = [
    EventTemplate(
      type: 'wedding',
      label: 'Wedding',
      tagline: 'Two souls, one beautiful journey',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "We're so blessed to have you in our lives. Instead of boxed gifts, help us fund our dream memories together! ✨",
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Honeymoon in Europe', description: 'Rome, Paris & Swiss Alps romantic getaway', icon: 'plane', amount: 300000),
        EventTemplateWishlistGoal(title: 'First Home Down Payment', description: 'Building our cozy sanctuary together', icon: 'house', amount: 1000000),
        EventTemplateWishlistGoal(title: 'Trip to Japan', description: 'Tokyo street food, Kyoto temples & Mt. Fuji cherry blossoms', icon: 'mountain', amount: 250000),
      ],
    ),
    EventTemplate(
      type: 'engagement',
      label: 'Engagement / Roka',
      tagline: 'A promise of forever begins today',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "Join us as we take our first step towards forever! Your presence and blessings mean the world to us.",
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Wedding Photography Fund', description: 'Capturing our special moments forever', icon: 'gem', amount: 150000),
        EventTemplateWishlistGoal(title: 'Couple Weekend Getaway', description: 'Pre-wedding recharge trip', icon: 'plane', amount: 60000),
      ],
    ),
    EventTemplate(
      type: 'birthday',
      label: 'Birthday Party',
      tagline: 'Another year bolder and wiser',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "Let's celebrate another year of life, laughter, and adventures! Come share your wishes and memories with us.",
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Dream Tech Gadget / Laptop', description: 'Creative workstation upgrade', icon: 'gift', amount: 80000),
        EventTemplateWishlistGoal(title: 'Solo Travel Adventure', description: 'Backpacking trip to Ladakh', icon: 'mountain', amount: 45000),
        EventTemplateWishlistGoal(title: 'Books & Learning Courses', description: 'Lifelong learning fund', icon: 'charity', amount: 15000),
      ],
    ),
    EventTemplate(
      type: 'baby_shower',
      label: 'Baby Shower / Seemantham',
      tagline: 'Welcoming our little miracle with love',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "A tiny feet is walking into our hearts! Join us in showering blessings upon our little blessing.",
      isPrivateByDefault: true,
      isChildEvent: true,
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Nursery Setup & Crib', description: 'Safe & cozy sanctuary for baby', icon: 'house', amount: 50000),
        EventTemplateWishlistGoal(title: 'Pram & Car Safety Seat', description: 'High-safety European certified gear', icon: 'gift', amount: 35000),
        EventTemplateWishlistGoal(title: 'Baby Stem Cell Banking', description: 'Health security fund', icon: 'charity', amount: 75000),
      ],
    ),
    EventTemplate(
      type: 'ear_piercing',
      label: 'Ear Piercing (Karnavedha)',
      tagline: 'A sacred childhood milestone of grace and protection',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "We celebrate our child's traditional Karnavedha ceremony. Your heartfelt blessings protect and guide our little one.",
      isPrivateByDefault: true,
      isChildEvent: true,
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Traditional Gold Earrings (Jimikki)', description: 'First 22K gold studs crafted with auspicious blessings', icon: 'gem', amount: 25000),
        EventTemplateWishlistGoal(title: 'Sukanya Samriddhi Education Fund', description: 'Long-term government savings account for college future', icon: 'charity', amount: 50000),
        EventTemplateWishlistGoal(title: 'Silver Anklets (Payal)', description: 'Traditional handcrafted auspicious silver payal', icon: 'gift', amount: 12000),
      ],
    ),
    EventTemplate(
      type: 'coming_of_age',
      label: 'Coming-of-Age (Upanayana / Ritu Kala)',
      tagline: 'Stepping into knowledge, wisdom and responsibility',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1609137144822-2617fef7b5a8?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "On this sacred transition, we invite our family to bless the path ahead with wisdom, courage, and virtue.",
      isPrivateByDefault: true,
      isChildEvent: true,
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Higher Education & Coding Laptop', description: 'Empowering future studies and growth', icon: 'gift', amount: 65000),
        EventTemplateWishlistGoal(title: 'Vedic Learning & Library Fund', description: 'Classical texts and study materials', icon: 'charity', amount: 20000),
      ],
    ),
    EventTemplate(
      type: 'housewarming',
      label: 'Housewarming (Griha Pravesh)',
      tagline: 'New walls, warm memories, eternal blessings',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "New Home, New Beginnings, New Memories! We are moving into our dream house. Come grace our home with your laughter and blessings.",
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Living Room Sectional Sofa', description: 'Comfortable seating where friends & family gather', icon: 'house', amount: 60000),
        EventTemplateWishlistGoal(title: 'Solar Rooftop Inverter System', description: 'Eco-friendly green power backup', icon: 'charity', amount: 75000),
        EventTemplateWishlistGoal(title: 'Kitchen Chimney & Smart Oven', description: 'For culinary experiments with family', icon: 'gift', amount: 40000),
      ],
    ),
    EventTemplate(
      type: 'graduation',
      label: 'Graduation / Convocation',
      tagline: 'Chasing passions, achieving dreams',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "Years of late-night study paid off! Help fuel the next chapter as I embark on my career journey.",
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Career Relocation Fund', description: 'Security deposit and setup in the new city', icon: 'house', amount: 50000),
        EventTemplateWishlistGoal(title: 'Professional Certification / MBA Prep', description: 'Advanced skilling fund', icon: 'charity', amount: 35000),
      ],
    ),
    EventTemplate(
      type: 'anniversary',
      label: 'Wedding Anniversary',
      tagline: 'Celebrating love that grows deeper with time',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "Another year of partnership, joy, and memories. Come raise a toast with us to many more happy chapters!",
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Silver Jubilee Cruise Vacation', description: 'Relaxing voyage across the Indian Ocean', icon: 'plane', amount: 120000),
        EventTemplateWishlistGoal(title: 'Home Garden Renovation', description: 'Creating our quiet morning tea oasis', icon: 'house', amount: 45000),
      ],
    ),
    EventTemplate(
      type: 'festival',
      label: 'Festival / Family Puja',
      tagline: 'Tradition, devotion, and festive togetherness',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1514517521153-1be72277b32f?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "May the divine grace fill our homes with peace, prosperity, and health. Join our annual family gathering and puja.",
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Community Annadanam (Food Drive)', description: 'Feeding 500 meals to underprivileged families', icon: 'charity', amount: 30000),
        EventTemplateWishlistGoal(title: 'Temple Renovation & Deepam Fund', description: 'Sacred lamps and flower seva', icon: 'gem', amount: 15000),
      ],
    ),
    EventTemplate(
      type: 'custom',
      label: 'Custom Occasion',
      tagline: 'Celebrate whatever matters to your heart',
      defaultCoverUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=1200&q=80',
      defaultStory: "We are gathering to celebrate something truly special! Come join our circle, share memories, and be part of our dream.",
      suggestedWishlist: [
        EventTemplateWishlistGoal(title: 'Celebration Goal Fund', description: 'A shared dream made possible by our loved ones', icon: 'gift', amount: 50000),
      ],
    ),
  ];

  static EventTemplate find(String type) {
    return all.firstWhere(
      (t) => t.type.toLowerCase() == type.toLowerCase(),
      orElse: () => all.last, // 'custom'
    );
  }
}
