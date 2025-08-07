import 'package:flutter/material.dart';

class NetflixAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSearchTap;

  const NetflixAppBar({
    Key? key,
    this.onProfileTap,
    this.onSearchTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          // Netflix Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE50914),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'NETFLIX',
            style: TextStyle(
              color: Color(0xFFE50914),
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        // Search Button
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 28),
          onPressed: onSearchTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función de búsqueda próximamente'),
                backgroundColor: Color(0xFFE50914),
              ),
            );
          },
        ),

        // Profile Button
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[800],
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}