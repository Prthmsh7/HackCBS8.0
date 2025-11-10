class AiCallState {
  final String mode; // "call" or "idle"
  final RecipeInfo? recipe;
  final int stepIndex;
  final int totalSteps;
  final List<TimerInfo> timers;
  final UserPrefs prefs;
  final List<PantryDelta> pantryDelta;
  final String notes;

  AiCallState({
    this.mode = "idle",
    this.recipe,
    this.stepIndex = 0,
    this.totalSteps = 0,
    List<TimerInfo>? timers,
    UserPrefs? prefs,
    List<PantryDelta>? pantryDelta,
    this.notes = "",
  })  : timers = timers ?? [],
        prefs = prefs ?? UserPrefs(),
        pantryDelta = pantryDelta ?? [];

  Map<String, dynamic> toJson() => {
        "mode": mode,
        "recipe": recipe?.toJson(),
        "step_index": stepIndex,
        "total_steps": totalSteps,
        "timers": timers.map((t) => t.toJson()).toList(),
        "prefs": prefs.toJson(),
        "pantry_delta": pantryDelta.map((p) => p.toJson()).toList(),
        "notes": notes,
      };

  AiCallState copyWith({
    String? mode,
    RecipeInfo? recipe,
    int? stepIndex,
    int? totalSteps,
    List<TimerInfo>? timers,
    UserPrefs? prefs,
    List<PantryDelta>? pantryDelta,
    String? notes,
  }) {
    return AiCallState(
      mode: mode ?? this.mode,
      recipe: recipe ?? this.recipe,
      stepIndex: stepIndex ?? this.stepIndex,
      totalSteps: totalSteps ?? this.totalSteps,
      timers: timers ?? this.timers,
      prefs: prefs ?? this.prefs,
      pantryDelta: pantryDelta ?? this.pantryDelta,
      notes: notes ?? this.notes,
    );
  }
}

class RecipeInfo {
  final String id;
  final String title;
  final int servings;

  RecipeInfo({
    required this.id,
    required this.title,
    required this.servings,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "servings": servings,
      };

  factory RecipeInfo.fromJson(Map<String, dynamic> json) => RecipeInfo(
        id: json["id"] ?? "",
        title: json["title"] ?? "",
        servings: json["servings"] ?? 2,
      );
}

class TimerInfo {
  final String label;
  final int seconds;
  final DateTime? endsAt;

  TimerInfo({
    required this.label,
    required this.seconds,
    this.endsAt,
  });

  Map<String, dynamic> toJson() => {
        "label": label,
        "seconds": seconds,
        "ends_at": endsAt?.toIso8601String(),
      };

  factory TimerInfo.fromJson(Map<String, dynamic> json) => TimerInfo(
        label: json["label"] ?? "",
        seconds: json["seconds"] ?? 0,
        endsAt: json["ends_at"] != null
            ? DateTime.parse(json["ends_at"])
            : null,
      );
}

class UserPrefs {
  final String diet;
  final String spice;
  final List<String> allergies;

  UserPrefs({
    this.diet = "",
    this.spice = "",
    List<String>? allergies,
  }) : allergies = allergies ?? [];

  Map<String, dynamic> toJson() => {
        "diet": diet,
        "spice": spice,
        "allergies": allergies,
      };

  factory UserPrefs.fromJson(Map<String, dynamic> json) => UserPrefs(
        diet: json["diet"] ?? "",
        spice: json["spice"] ?? "",
        allergies: List<String>.from(json["allergies"] ?? []),
      );
}

class PantryDelta {
  final String item;
  final double delta;
  final String unit;

  PantryDelta({
    required this.item,
    required this.delta,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
        "item": item,
        "delta": delta,
        "unit": unit,
      };

  factory PantryDelta.fromJson(Map<String, dynamic> json) => PantryDelta(
        item: json["item"] ?? "",
        delta: (json["delta"] ?? 0).toDouble(),
        unit: json["unit"] ?? "",
      );
}




