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

class _QuizAttemptScreenState extends State<QuizAttemptScreen> with WidgetsBindingObserver {
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
    if (state != AppLifecycleState.resumed && !isSubmitting && !autoSubmitted) {
      _autoSubmit("App switched / Background detected");
    }
  }

  void startTimer() {
    remainingSeconds = quiz.questions.length * 60; // 1 min per question
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

  void select(String answer) {
    if (lockedQuestions.contains(currentIndex)) return;
    setState(() {
      selectedAnswers[currentIndex] = answer;
      lockedQuestions.add(currentIndex);
    });
  }

  void next() {
    if (currentIndex < quiz.questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      submit();
    }
  }

  Future<void> _autoSubmit(String reason) async {
    if (autoSubmitted || isSubmitting) return;
    autoSubmitted = true;
    timer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Auto-submitted: $reason"), backgroundColor: Colors.red));
    await submit();
  }

  Future<void> submit() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);
    timer?.cancel();

    final provider = context.read<QuizProvider>();
    final answers = quiz.questions.asMap().entries.map((e) {
      return {"selectedAnswer": selectedAnswers[e.key] ?? ""};
    }).toList();

    final result = await provider.attemptQuiz(quiz.id, quizId: quiz.id, answers: answers);
    setState(() => isSubmitting = false);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/quiz-result', arguments: result ?? quiz); // Fallback to quiz if result null
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = quiz.questions[currentIndex];
    final selected = selectedAnswers[currentIndex];
    final progress = (currentIndex + 1) / quiz.questions.length;
    final optionEntries = q.options?.entries.toList() ?? [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot go back during an active quiz!"), backgroundColor: Colors.orange));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Question ${currentIndex + 1} of ${quiz.questions.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.timer, color: Colors.red, size: 16), const SizedBox(width: 4), Text(formatTime(remainingSeconds), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey.shade200, color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(10)),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)), child: Text(q.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4))),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: optionEntries.length,
                  itemBuilder: (c, i) {
                    final key = optionEntries[i].key;
                    final value = optionEntries[i].value;
                    final isSelected = selected == key;

                    return GestureDetector(
                      onTap: () => select(key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 16, backgroundColor: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200, child: Text(key, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: isSelected ? const Color(0xFF4F46E5) : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
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
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : next,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(currentIndex == quiz.questions.length - 1 ? "Submit Final Answers" : "Next Question", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}