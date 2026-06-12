import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:provider/provider.dart';

class QuizAttemptScreen extends StatefulWidget {
  const QuizAttemptScreen({super.key});
  static const String routeName = '/quiz-attempt';

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen>
    with WidgetsBindingObserver {
      
  late Quiz quiz;

  int currentIndex = 0;
  Map<int, String> selectedAnswers = {};
  Set<int> lockedQuestions = {};

  bool isSubmitting = false;
  bool autoSubmitted = false;

  Timer? timer;
  int remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    quiz = ModalRoute.of(context)!.settings.arguments as Quiz;

    if (timer == null) startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _autoSubmit("App switched / background detected");
    }
  }

  void startTimer() {
    remainingSeconds = quiz.questions.length * 60;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds <= 0) {
        t.cancel();
        _autoSubmit("Time finished");
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  String formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ================= ANSWER SELECT =================
  void select(String answer) {
    if (lockedQuestions.contains(currentIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠ Answer is locked for this question"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      selectedAnswers[currentIndex] = answer;
      lockedQuestions.add(currentIndex);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Answer locked"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ================= NEXT WITH SKIP CHECK =================
  void next() {
    if (!selectedAnswers.containsKey(currentIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠ Question skipped (no answer selected)"),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (currentIndex < quiz.questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      _autoSubmit("Last question reached");
    }
  }

  Future<void> _autoSubmit(String reason) async {
    if (autoSubmitted || isSubmitting) return;

    autoSubmitted = true;
    timer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Quiz auto-submitted: $reason"),
        backgroundColor: Colors.red,
      ),
    );

    await submit();
  }

  Future<void> submit() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);
    timer?.cancel();

    final provider = context.read<QuizProvider>();

    final answers = quiz.questions.asMap().entries.map((e) {
      return {
        "selectedAnswer": selectedAnswers[e.key] ?? "",
      };
    }).toList();

    final result = await provider.attemptQuiz(
      quiz.id, quizId: quiz.id,
      answers: answers,
    );

    setState(() => isSubmitting = false);

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/quiz-result',
      arguments: result,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<bool> _onWillPop() async => false;

  @override
  Widget build(BuildContext context) {
    final q = quiz.questions[currentIndex];
    final selected = selectedAnswers[currentIndex];
    final progress = (currentIndex + 1) / quiz.questions.length;
     final optionEntries = q.options?.entries.toList() ?? [];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Question ${currentIndex + 1}/${quiz.questions.length}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      formatTime(remainingSeconds),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  q.question,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 20),

Expanded(
  child: ListView.builder(
    itemCount: optionEntries.length,
    itemBuilder: (c, i) {
      final entry = optionEntries[i];

      final key = entry.key;     // A / B / C / D
      final value = entry.value; // actual text

      final isSelected = selected == key;

      return GestureDetector(
        onTap: () => select(key),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5).withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "$key. $value", 
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF22C55E),
                ),
            ],
          ),
        ),
      );
    },
  ),
)
            ],
          ),
        ),

        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isSubmitting ? null : next,
              child: Text(
                currentIndex == quiz.questions.length - 1
                    ? "Submit Quiz"
                    : "Next Question",
              ),
            ),
          ),
        ),
      ),
    );
  }
}
