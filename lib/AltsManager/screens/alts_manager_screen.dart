import 'package:flutter/material.dart';
import '../../Core/theme/app_theme.dart';

class AltsManagerScreen extends StatefulWidget {
  const AltsManagerScreen({super.key});

  @override
  State<AltsManagerScreen> createState() => _AltsManagerScreenState();
}

class _AltsManagerScreenState extends State<AltsManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.skyBlue,
                      AppColors.steelBlue,
                      AppColors.dodgerBlue,
                    ],
                  ),
                ),
              ),
              title: Row(
                children: [
                  Image.asset(
                    'images/accountManager.png',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Alts Manager',
                    style: TextStyle(
                      fontFamily: 'Urbanist-Regular',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        Image.asset(
                          'images/accountManager.png',
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Alts Manager',
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Manage your alternative accounts and collaborators',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Urbanist-Regular',
                            fontSize: 16,
                            color: AppColors.background.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
