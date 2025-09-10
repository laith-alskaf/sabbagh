import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';

// ignore: must_be_immutable
class DropMenuJob extends StatelessWidget {
  const DropMenuJob({
    super.key,
    required this.items,
    this.onSaved,
    this.suffixIcon,
    this.textEditingController,
    this.hintText,
    this.validator,
    required this.messageError,
    this.value,
  });

  final List<String> items;
  final Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final String messageError;
  final String? value;
  final TextEditingController? textEditingController;
  final Widget? suffixIcon;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField2<String>(
      isExpanded: true,
      value: value,
      style: TextStyle(
        color: AppColors.primaryGreen,
        overflow: TextOverflow.ellipsis,
      ),
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: AppColors.white,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryGreen),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryGreen),
        ),
        border: const UnderlineInputBorder(),
      ),
      items:
          items.map<DropdownMenuItem<String>>((value) {
            return DropdownMenuItem<String>(
              alignment: Alignment.center,
              value: value,
              child: Text(
                value.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.black, // تغيير إلى أسود للوضوح
                ),
              ),
            );
          }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((String value) {
          return Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.black, // تغيير إلى أسود للوضوح
            ),
          );
        }).toList();
      },
      validator: (value) {
        if (value == null) {
          return messageError;
        }
        return null;
      },
      dropdownSearchData:
          textEditingController == null
              ? null
              : DropdownSearchData(
                searchController: textEditingController,
                searchInnerWidgetHeight: 50,
                searchInnerWidget: Container(
                  height: 50,
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 4,
                    right: 8,
                    left: 8,
                  ),
                  child: TextFormField(
                    onChanged: onSaved,
                    expands: true,
                    maxLines: null,
                    controller: textEditingController,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      hintText: 'Search for an item...',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                searchMatchFn: (item, searchValue) {
                  return item.value.toString().contains(searchValue);
                },
              ),
      onMenuStateChange:
          textEditingController == null
              ? null
              : (isOpen) {
                if (!isOpen) {
                  textEditingController!.clear();
                }
              },
      onChanged: onSaved,
      onSaved: onSaved,
      dropdownStyleData: DropdownStyleData(
        maxHeight: 200,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      menuItemStyleData: MenuItemStyleData(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      ),
    );
  }
}
