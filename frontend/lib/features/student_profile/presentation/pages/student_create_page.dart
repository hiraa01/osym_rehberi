import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../providers/student_form_provider.dart';
import '../widgets/student_form_step1.dart';
import '../widgets/student_form_step2.dart';
import '../widgets/student_form_step3.dart';
import '../widgets/student_form_step4.dart';

@RoutePage()
class StudentCreatePage extends ConsumerStatefulWidget {
  const StudentCreatePage({super.key});

  @override
  ConsumerState<StudentCreatePage> createState() => _StudentCreatePageState();
}

class _StudentCreatePageState extends ConsumerState<StudentCreatePage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(studentFormProvider);
    final formNotifier = ref.read(studentFormProvider.notifier);

    // Listen for errors and show a SnackBar
    ref.listen<StudentFormState>(studentFormProvider, (previous, next) {
      if (next.error != null && (previous?.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Animate to current step when it changes
      if (previous != null && previous.currentStep != next.currentStep) {
        _pageController.animateToPage(
          next.currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Öğrenci Profili'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getMaxContentWidth(context),
              ),
              child: Column(
                children: [
                  // Progress Indicator
                  Container(
                    padding: ResponsiveUtils.getResponsivePadding(context),
                    child: Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (formState.currentStep + 1) / 4,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                        Text(
                          '${formState.currentStep + 1}/4',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                          ),
                        ),
                      ],
                    ),
                  ),
          
                  // Form Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) {
                        formNotifier.setCurrentStep(page);
                      },
                      children: const [
                        StudentFormStep1(),
                        StudentFormStep2(),
                        StudentFormStep3(),
                        StudentFormStep4(),
                      ],
                    ),
                  ),
                  
                  // Navigation Buttons
                  Container(
                    padding: ResponsiveUtils.getResponsivePadding(context),
                    child: Row(
                      children: [
                        if (formState.currentStep > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: formNotifier.previousStep,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
                                ),
                              ),
                              child: const Text('Geri'),
                            ),
                          ),
                        if (formState.currentStep > 0) 
                          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: formState.isLoading
                                ? null
                                : (formState.currentStep < 3
                                    ? formNotifier.nextStep
                                    : () => _submitForm(context, ref)),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
                              ),
                            ),
                            child: formState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    formState.currentStep < 3 ? 'İleri' : 'Kaydet',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitForm(BuildContext context, WidgetRef ref) async {
    final formNotifier = ref.read(studentFormProvider.notifier);
    
    try {
      await formNotifier.submitForm();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Öğrenci profili başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
