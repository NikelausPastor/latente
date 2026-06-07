import 'chemical.dart';
import 'development_recipe.dart';
import 'development_session.dart';
import 'film.dart';

class AppData {
  const AppData({
    required this.films,
    required this.chemicals,
    required this.recipes,
    required this.sessions,
  });

  final List<Film> films;
  final List<Chemical> chemicals;
  final List<DevelopmentRecipe> recipes;
  final List<DevelopmentSession> sessions;

  factory AppData.empty() {
    return const AppData(
      films: [],
      chemicals: [],
      recipes: [],
      sessions: [],
    );
  }

  AppData copyWith({
    List<Film>? films,
    List<Chemical>? chemicals,
    List<DevelopmentRecipe>? recipes,
    List<DevelopmentSession>? sessions,
  }) {
    return AppData(
      films: films ?? this.films,
      chemicals: chemicals ?? this.chemicals,
      recipes: recipes ?? this.recipes,
      sessions: sessions ?? this.sessions,
    );
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      films: ((json['pellicole'] as List?) ?? (json['films'] as List?) ?? [])
          .map((item) => Film.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      chemicals:
          ((json['chimici'] as List?) ?? (json['chemicals'] as List?) ?? [])
              .map(
                (item) =>
                    Chemical.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
      recipes: ((json['ricetteSviluppo'] as List?) ??
              (json['recipes'] as List?) ??
              [])
          .map(
            (item) => DevelopmentRecipe.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      sessions: ((json['storicoLavorazioni'] as List?) ??
              (json['sessions'] as List?) ??
              [])
          .map(
            (item) => DevelopmentSession.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pellicole': films.map((film) => film.toJson()).toList(),
      'chimici': chemicals.map((chemical) => chemical.toJson()).toList(),
      'ricetteSviluppo': recipes.map((recipe) => recipe.toJson()).toList(),
      'storicoLavorazioni':
          sessions.map((session) => session.toJson()).toList(),
    };
  }
}
