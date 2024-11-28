import 'package:flutter/material.dart';

class WorkoutGuideOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;

  const WorkoutGuideOverlay({
    super.key,
    required this.isVisible,
    required this.onClose,
  });

  @override
  State<WorkoutGuideOverlay> createState() => _WorkoutGuideOverlayState();
}

class _WorkoutGuideOverlayState extends State<WorkoutGuideOverlay> {
  int _currentStep = 0;
  final _guideSteps = [
    GuideStep(
      title: '기본 자세',
      description: '발을 어깨 너비로 벌리고 시선은 정면을 바라봅니다.',
      icon: Icons.accessibility_new,
      image: 'assets/images/squat_1.png',
    ),
    GuideStep(
      title: '내려가는 자세',
      description: '엉덩이를 뒤로 빼면서 천천히 무릎을 굽힙니다.\n무릎이 발끝을 넘어가지 않도록 주의하세요.',
      icon: Icons.arrow_downward,
      image: 'assets/images/squat_2.png',
    ),
    GuideStep(
      title: '스쿼트 자세',
      description: '허벅지가 바닥과 평행이 될 때까지 내려갑니다.\n허리는 곧게 펴고 있어야 합니다.',
      icon: Icons.square,
      image: 'assets/images/squat_3.png',
    ),
    GuideStep(
      title: '올라오는 자세',
      description: '발뒤꿈치로 바닥을 밀면서 천천히 일어납니다.\n무릎과 발이 같은 방향을 향하도록 유지하세요.',
      icon: Icons.arrow_upward,
      image: 'assets/images/squat_4.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '올바른 스쿼트 자세 가이드',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                itemCount: _guideSteps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                itemBuilder: (context, index) {
                  final step = _guideSteps[index];
                  return _buildGuideStep(step);
                },
              ),
            ),
            _buildStepIndicator(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('이전'),
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                    )
                  else
                    const SizedBox(width: 100),
                  if (_currentStep < _guideSteps.length - 1)
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('다음'),
                      onPressed: () {
                        setState(() {
                          _currentStep++;
                        });
                      },
                    )
                  else
                    ElevatedButton(
                      onPressed: widget.onClose,
                      child: const Text('시작하기'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(GuideStep step) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            step.icon,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            step.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (step.image != null)
            Image.asset(
              step.image!,
              height: 200,
              fit: BoxFit.contain,
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _guideSteps.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentStep ? Colors.blue : Colors.white30,
          ),
        ),
      ),
    );
  }
}

class GuideStep {
  final String title;
  final String description;
  final IconData icon;
  final String? image;

  GuideStep({
    required this.title,
    required this.description,
    required this.icon,
    this.image,
  });
}
