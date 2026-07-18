import 'package:flutter/widgets.dart';
import 'package:ionicons/ionicons.dart';

import '../navigation/routes.dart';

/// Static copy for the About screen. Placeholder text — swap for real
/// library-provided copy when available.
const String aboutDescription =
    "The Junaid Zaidi Library at COMSATS University Islamabad serves the university's academic community with an extensive collection of books, journals, theses, and digital resources, along with study spaces designed to support research and learning.";

class InchargeMessage {
  final String name;
  final String message;

  const InchargeMessage({required this.name, required this.message});
}

const InchargeMessage inchargeMessage = InchargeMessage(
  name: 'Library In-Charge',
  message:
      'Welcome to the Junaid Zaidi Library. Our goal is to provide a welcoming, well-resourced environment where every student and faculty member can pursue knowledge with ease. We continue to expand our collections and services to better serve our community.',
);

/// Clickable bars below the short intro sections. Each links to its own screen.
class AboutLink {
  final String key;
  final String label;
  final IconData icon;
  final String routeName;

  const AboutLink({
    required this.key,
    required this.label,
    required this.icon,
    required this.routeName,
  });
}

final List<AboutLink> aboutLinks = [
  const AboutLink(
    key: 'facts',
    label: 'Facts about Junaid Zaidi Library',
    icon: Ionicons.sparkles_outline,
    routeName: MoreRoutes.aboutFacts,
  ),
  const AboutLink(
    key: 'rules',
    label: 'Rules and Regulations',
    icon: Ionicons.shield_checkmark_outline,
    routeName: MoreRoutes.aboutRules,
  ),
  const AboutLink(
    key: 'staff',
    label: 'Staff Info',
    icon: Ionicons.people_outline,
    routeName: MoreRoutes.aboutStaff,
  ),
  const AboutLink(
    key: 'floor-plan',
    label: 'Floor Plan',
    icon: Ionicons.layers_outline,
    routeName: MoreRoutes.aboutFloorPlan,
  ),
];

final List<String> libraryFacts = [
  'Multiple floors of dedicated reading, reference, and periodical sections.',
  'Group study rooms available for collaborative work.',
  "A dedicated women's section and quiet study areas.",
  'Public computer cubicles for catalog and research access.',
  'On-site coffee shop for a study break.',
];

final List<String> libraryRules = [
  'Library cards must be presented for book borrowing and entry.',
  'Silence must be maintained in reading and study areas.',
  'Food and drinks are not allowed inside the reading halls.',
  'Borrowed items must be returned by the due date to avoid fines.',
  'Damaging or defacing library material is strictly prohibited.',
];

class StaffMember {
  final String name;
  final String role;

  const StaffMember({required this.name, required this.role});
}

final List<StaffMember> staffDirectory = [
  const StaffMember(name: 'Library In-Charge', role: 'Head of Library Services'),
  const StaffMember(name: 'Deputy In-Charge', role: 'Circulation & Collections'),
  const StaffMember(name: 'Reference Librarian', role: 'Research & Reference Desk'),
  const StaffMember(name: 'Systems Librarian', role: 'Digital Resources & OPAC'),
];
