import 'package:flutter/material.dart';

class IconPicker extends StatelessWidget {
  final int selectedIcon;
  final ValueChanged<int> onIconSelected;

  const IconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  static const List<IconData> _icons = [
    Icons.account_balance,
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.savings,
    Icons.monetization_on,
    Icons.business,
    Icons.store,
    Icons.home,
    Icons.directions_car,
    Icons.card_giftcard,
    Icons.school,
    Icons.phone_android,
    Icons.local_grocery_store,
    Icons.local_mall,
    Icons.local_atm,
    Icons.local_offer,
    Icons.attractions,
    Icons.invert_colors,
    Icons.center_focus_strong,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _icons.length,
        itemBuilder: (context, index) {
          final icon = _icons[index];
          final isSelected = icon.codePoint == selectedIcon;
          return GestureDetector(
            onTap: () => onIconSelected(icon.codePoint),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          );
        },
      ),
    );
  }
}
