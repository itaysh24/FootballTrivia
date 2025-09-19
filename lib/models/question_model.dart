class Question {
  final String answer;
  final List<String> careerPath;

  Question({required this.answer, required this.careerPath});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      answer: json['answer'],
      careerPath: List<String>.from(json['careerPath']),
    );
  }
}
