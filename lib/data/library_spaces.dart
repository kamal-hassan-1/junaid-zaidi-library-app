import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/accents.dart';
import 'library_images.dart';

/// One library space shown on the Spaces tab (in-app detail, not a redirect).
class LibrarySpace {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final AppAccent accent;
  final List<String> imagePaths;
  final List<String> paragraphs;
  final String? conditionsTitle;
  final List<String> conditions;
  final String? reservationTitle;
  final List<String> reservationSteps;

  /// When set, this address is rendered as a tappable mailto link in the
  /// reservation block (Video / Conference rooms).
  final String? reservationEmail;

  const LibrarySpace({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.imagePaths,
    required this.paragraphs,
    this.conditionsTitle,
    this.conditions = const [],
    this.reservationTitle,
    this.reservationSteps = const [],
    this.reservationEmail,
  });
}

/// Spaces listed on the Spaces tab — content adapted from library.comsats.edu.pk.
final List<LibrarySpace> librarySpaces = [
  const LibrarySpace(
    id: 'video-conference-room',
    title: 'Video Conference Room',
    subtitle: 'Basement · seating for 58',
    icon: LucideIcons.video,
    accent: AppAccent.brand,
    imagePaths: [basementConferenceRoomImagePath],
    paragraphs: [
      'Video conferencing lets users in different locations hold face-to-face meetings without gathering in one place. Seeing each other helps build stronger relationships than telephone conference calls alone.',
      'The Video Conference Room is one of the unique spaces in the Junaid Zaidi Library, designed for modern information and communication technologies. Faculty members and research scholars frequently use it for trainings, seminars, thesis defenses, and official meetings.',
      'It has a seating capacity of 58 and is equipped with the latest ICTs and infrastructure.',
    ],
    reservationTitle: 'Procedure of Reservation',
    reservationSteps: [
      'To make a prior reservation for an upcoming event, users need to contact Junaid Zaidi Library administration by emailing at muhammad_asif@comsats.edu.pk',
    ],
    reservationEmail: 'muhammad_asif@comsats.edu.pk',
  ),
  const LibrarySpace(
    id: 'conference-room',
    title: 'Conference Room',
    subtitle: 'Basement · 12–15 seats',
    icon: LucideIcons.presentation,
    accent: AppAccent.success,
    imagePaths: [conferenceRoomImagePath],
    paragraphs: [
      'Junaid Zaidi Library has a dedicated Conference Room for meetings and presentations. It is located in the basement and seats about 12–15 members.',
      'The room supports academic and official needs of the CUI community. It is equipped with a whiteboard and multimedia system.',
      'Usage is typically limited to 1–2 hours. Extensions may be granted when there is no standing reservation for the next slot.',
    ],
    reservationTitle: 'Procedure of Reservation',
    reservationSteps: [
      'To make a prior reservation for an upcoming event, users need to contact Junaid Zaidi Library administration by emailing at muhammad_asif@comsats.edu.pk',
    ],
    reservationEmail: 'muhammad_asif@comsats.edu.pk',
  ),
  const LibrarySpace(
    id: 'group-study-rooms',
    title: 'Group Study Rooms',
    subtitle: '7 rooms · 8–10 seats each',
    icon: LucideIcons.users,
    accent: AppAccent.warning,
    imagePaths: [groupStudyRoomsImagePath],
    paragraphs: [
      'Junaid Zaidi Library has dedicated Group Study/Discussion Rooms for student collaboration. There are 7 rooms across the floors (except the ground floor). Each seats about 8–10 students and includes a whiteboard.',
      'These rooms are meant for study-related discussion. They are not soundproof, so only light discussion is allowed.',
    ],
    conditionsTitle: 'Conditions of Use',
    conditions: [
      'Minimum 3 and maximum 10 users.',
      'Maximum usage is 1 hour; extensions are allowed if the next hour is free.',
      'Do not leave personal belongings unattended.',
      'Do not use rooms for social or entertainment purposes (e.g. movies, parties, chatting).',
      'No food or drinks.',
      'Use only the chairs and table provided; do not move furniture in from elsewhere.',
      'Leave the room neat and tidy; return library materials to the counter.',
      'Bookings are cancelled if you arrive more than 15 minutes late.',
      'Inspect the room before use and report any existing damage.',
      'Keep noise to a minimum out of consideration for others.',
      'If you leave for lunch or another reason, inform front desk staff.',
      'The library is not responsible for lost or stolen property.',
      'All rooms must be vacated by 8:50 p.m. on weekdays.',
      'Failure to follow policies may lead to suspension of privileges.',
      'The library may end use that disrupts others or normal operations.',
    ],
    reservationTitle: 'Procedure of Reservation',
    reservationSteps: [
      'Reservations are on the spot, subject to availability.',
      'Rooms are issued to groups of 3–10 students (based on availability and room size).',
      'A student waiting alone for group members cannot hold a reservation.',
      'Information Desk staff may cancel a reservation or ask users to vacate for guideline violations.',
      'A single student may use a room only with special permission from the floor in-charge.',
    ],
  ),
  const LibrarySpace(
    id: 'research-cubicles',
    title: 'Research Cubicles',
    subtitle: '2nd floor · quiet focus',
    icon: LucideIcons.square_pen,
    accent: AppAccent.error,
    imagePaths: [publicComputerCubiclesImagePath],
    paragraphs: [
      'Research cubicles on the 2nd floor provide a quiet, focused environment for research productivity—similar to cubicles in university libraries worldwide.',
      'They offer privacy for deep work such as reading, writing, or data analysis, which is especially useful for sensitive or confidential research.',
      'Cubicles are placed near reference materials and databases so researchers can access resources easily. Each workspace can be organized to suit individual preferences.',
      'They include power outlets and internet connectivity for laptops, tablets, and other devices. Cubicles can be reserved in advance so researchers have a dedicated space when needed.',
      'Together they support a professional atmosphere of research and academic excellence within the library.',
    ],
  ),
  const LibrarySpace(
    id: 'reading-corner',
    title: 'Reading Corner',
    subtitle: '2nd floor · quiet reading',
    icon: LucideIcons.book_open,
    accent: AppAccent.brand,
    imagePaths: [magazineShelfImagePath],
    paragraphs: [
      'The Reading Corner on the 2nd floor promotes a love of reading, supports research and inquiry, and fosters community within the university.',
      'It is a visible reminder of reading\'s value for academic and personal enrichment, offering a comfortable, quiet place for focused study and reflection.',
      'Students can engage with course materials, conduct research, and explore supplementary readings. The area is near a range of textbooks, reference works, fiction, and non-fiction.',
      'Reading here supports critical thinking—engaging with complex ideas, analyzing arguments, and building analytical skills—while also offering a place to unwind and reduce stress.',
      'It is also a communal spot to discuss books, share recommendations, and pursue self-directed learning beyond the curriculum.',
    ],
  ),
  const LibrarySpace(
    id: 'phd-research-lab',
    title: 'PhD Research Lab',
    subtitle: '1st floor · researchers',
    icon: LucideIcons.graduation_cap,
    accent: AppAccent.success,
    imagePaths: [phdResearchLabImagePath],
    paragraphs: [
      'The PhD Research Lab on the 1st floor links research with access to academic resources. It offers a collaborative, supportive setting for PhD students and researchers.',
      'The space is comfortable and quiet—suited to focused study, literature review, gathering information, and planning research directions.',
      'Researchers can discuss books and articles, share recommendations, and build a sense of community and collaboration.',
      'Its creative, professional atmosphere supports innovation and academic excellence within the Junaid Zaidi Library.',
    ],
  ),
  const LibrarySpace(
    id: 'khatoon-corner',
    title: 'Khatoon Corner',
    subtitle: 'Dedicated space for women',
    icon: LucideIcons.heart,
    accent: AppAccent.warning,
    imagePaths: [womenCornerImagePath],
    paragraphs: [
      'Khatoon Corner is designed for female students, supporting a more inclusive and comfortable learning environment tailored to their preferences and needs.',
      'It aims to be a safe, respectful space with reading materials that reflect diverse interests and perspectives, including literature by and about women.',
      'Comfortable seating—such as cozy chairs, cushions, or bean bags—creates a welcoming atmosphere. Resources on leadership, women\'s achievements, and gender equality help foster empowerment.',
      'Collaborative areas support group discussions and study sessions. The corner is well-lit and quiet for concentration, and designed to be accessible, including for students with physical disabilities.',
      'Partnerships with women\'s groups on campus help shape initiatives and build community around the space.',
    ],
  ),
  const LibrarySpace(
    id: 'art-gallery',
    title: 'Art Gallery',
    subtitle: 'Basement · exhibitions',
    icon: LucideIcons.palette,
    accent: AppAccent.error,
    imagePaths: [artGallery1ImagePath, artGallery2ImagePath],
    paragraphs: [
      'The art gallery in the basement enriches the educational and cultural experience of the library community. It supports artistic expression, creativity, and interdisciplinary connections.',
      'Students, faculty, and visitors can engage with diverse art forms, cultures, identities, and styles—promoting inclusivity and cultural appreciation.',
      'Exposure to art can inspire projects, research, and creative work. Exhibitions give the community a place to showcase talent and celebrate artistic endeavors.',
      'Open exhibitions, artist talks, and workshops can engage both the university and the local community. The gallery also offers a visually stimulating place for relaxation and reflection away from academic pressure.',
    ],
  ),
  const LibrarySpace(
    id: 'coffee-shop',
    title: 'Coffee Shop',
    subtitle: 'Basement · refreshments',
    icon: LucideIcons.coffee,
    accent: AppAccent.brand,
    imagePaths: [coffeeShop1ImagePath],
    paragraphs: [
      'The coffee shop in the basement lets students, faculty, and visitors grab a coffee or snack without leaving the library—especially useful during long study or research sessions.',
      'It doubles as a social hub: a relaxed place to meet, chat, or collaborate, and an informal setting for discussions with professors, classmates, or project groups.',
      'Access to beverages and refreshments helps sustain longer study sessions. The layout and color scheme are meant to feel cohesive with the library\'s purpose.',
      'The menu aims to cover varied tastes and dietary needs—hot and cold drinks, snacks, and light options, with caffeinated and non-caffeinated choices. Hours generally follow the library\'s schedule, with possible extensions during peak study periods.',
    ],
  ),
];

LibrarySpace? librarySpaceById(String id) {
  for (final space in librarySpaces) {
    if (space.id == id) return space;
  }
  return null;
}
