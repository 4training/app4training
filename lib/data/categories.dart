import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Trying out worksheet categories: First hardcode them here
enum Category {
  essentials,
  essentialsForTrainers,
  innerHealing,
  innerHealingForTrainers;

  static String getLocalized(BuildContext context, Category value) {
    switch (value) {
      case Category.essentials:
        return context.l10n.essentials;
      case Category.essentialsForTrainers:
        return context.l10n.essentialsForTrainers;
      case Category.innerHealing:
        return context.l10n.innerHealing;
      case Category.innerHealingForTrainers:
        return context.l10n.innerHealingForTrainers;
    }
  }
}

/// Which worksheet belongs to which category?
const Map<String, Category> worksheetCategories = {
  "God's_Story_(five_fingers)": Category.essentials,
  "God's_Story_(first_and_last_sacrifice)": Category.essentials,
  "Baptism": Category.essentials,
  "Prayer": Category.essentials,
  "Forgiving_Step_by_Step": Category.essentials,
  "Confessing_Sins_and_Repenting": Category.essentials,
  "Time_with_God": Category.essentials,
  "Hearing_from_God": Category.essentials,
  "Church": Category.essentials,
  "Healing": Category.essentials,
  "Dealing_with_Money": Category.essentials,
  "My_Story_with_God": Category.essentials,
  "Bible_Reading_Hints": Category.essentials,
  "Bible_Reading_Hints_(Seven_Stories_full_of_Hope)": Category.essentials,
  "Bible_Reading_Hints_(Starting_with_the_Creation)": Category.essentials,
  "The_Three-Thirds_Process": Category.essentialsForTrainers,
  "Training_Meeting_Outline": Category.essentialsForTrainers,
  "Overcoming_Fear_and_Anger": Category.innerHealing,
  "Getting_Rid_of_Colored_Lenses": Category.innerHealing,
  "Family_and_our_Relationship_with_God": Category.innerHealing,
  "Overcoming_Pride_and_Rebellion": Category.innerHealing,
  "Overcoming_Negative_Inheritance": Category.innerHealing,
  "Forgiving_Step_by_Step:_Training_Notes": Category.innerHealingForTrainers,
  "Leading_Others_Through_Forgiveness": Category.innerHealingForTrainers,
  "The_Role_of_a_Helper_in_Prayer": Category.innerHealingForTrainers,
  "Leading_a_Prayer_Time": Category.innerHealingForTrainers,
  "How_to_Continue_After_a_Prayer_Time": Category.innerHealing,
  "Four_Kinds_of_Disciples": Category.essentialsForTrainers
};
