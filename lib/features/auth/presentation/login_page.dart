import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/forestring_theme.dart';
import 'auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _autoLogin = false;

  bool get _canLogin =>
      _nameController.text.trim().isNotEmpty &&
      _pinController.text.length == 4;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
    _pinController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_refresh)
      ..dispose();
    _pinController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _login() async {
    if (!_canLogin) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    await context.read<AuthController>().signIn(
          name: _nameController.text,
          pin: _pinController.text,
          rememberSession: _autoLogin,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: keyboardVisible
                          ? 24
                          : constraints.maxHeight * 0.55,
                      child: keyboardVisible
                          ? const SizedBox.shrink()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/img/student_login_logo.png',
                                  width: width * 0.73,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  '포레스트링 수강생',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          '자동 로그인',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 13,
                          ),
                        ),
                        CupertinoSwitch(
                          value: _autoLogin,
                          inactiveTrackColor: Colors.white60,
                          activeTrackColor: const Color(0xff3E6F58),
                          onChanged: auth.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _autoLogin = value;
                                  });
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        labelText: '아이디',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onSubmitted: (_) => _login(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        labelText: '비밀번호',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        auth.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor:
                              _canLogin ? Colors.white : Colors.grey,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            auth.isLoading || !_canLogin ? null : _login,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              )
                            : const Text(
                                '로그인',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
