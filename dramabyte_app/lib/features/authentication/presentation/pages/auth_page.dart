import 'package:dramabyte_app/components/flare_buttons.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static final _codePattern = RegExp(r'^[A-Za-z0-9]{6,12}$');
  final _referralController = TextEditingController();

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  void _signInWithGoogle() {
    final code = _referralController.text.trim();
    if (code.isNotEmpty && !_codePattern.hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid referral code')),
      );
      return;
    }
    context.read<AuthenticationBloc>().add(
      GoogleSignInRequested(referralCode: code.isEmpty ? null : code),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listenWhen: (_, state) =>
          state is Unauthenticated && state.message != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((state as Unauthenticated).message!)),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 20.w),
                  child: FlareText(
                    'SHOW BEGIN NOW',
                  ).white.bold.pb(2.h).size(120.w),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 20.w),
                  child: FlareText(
                    'SHOW BEGIN NOW',
                  ).white.bold.pb(2.h).size(120.w),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height / 6,
              right: 40.w,
              child: Center(
                child: Image.asset(
                  'assets/images/authpagebg.png',
                  height: MediaQuery.of(context).size.height.h,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.r),
                    topRight: Radius.circular(25.r),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.r),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlareText('Home of drama').xl5.black.semiBold.pb(2.h),
                      FlareText(
                        'Register your account and continue watching your favourote dramas. Welcome back.',
                      ).black.center.pb(20.h),
                      TextField(
                        controller: _referralController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 12,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Referral code (optional)',
                          prefixIcon: Icon(MdiIcons.giftOutline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      FlareButton(
                        label: 'Continue with apple',
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Apple sign-in is coming soon'),
                              ),
                            ),
                        borderRadius: BorderRadius.circular(100.r),
                        borderColor: Colors.black,
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        icon: Icon(MdiIcons.apple),
                      ),
                      SizedBox(height: 12),
                      FlareButton(
                        label: 'Continue with google',
                        isLoading: context.select(
                          (AuthenticationBloc bloc) =>
                              bloc.state is AuthenticationLoading,
                        ),
                        onPressed: _signInWithGoogle,
                        borderRadius: BorderRadius.circular(100.r),
                        borderColor: Colors.black,
                        backgroundColor: Colors.white,
                        icon: Icon(MdiIcons.google),
                      ),
                      SizedBox(height: 20.h),
                      FlareText(
                        "By clicking on continue with 'apple' or 'google' you agree our terms and policies",
                      ).center.black.xs,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
