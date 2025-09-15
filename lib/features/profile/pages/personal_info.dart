import 'package:flutter/material.dart';
import 'package:Soulene/shared/models/user_model.dart';
import 'package:Soulene/core/services/api_service.dart';
import 'package:Soulene/core/theme/app_theme.dart';
import 'package:intl/intl.dart';


class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({Key? key}) : super(key: key);

  Widget buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white38,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );
  }

  Widget buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(
              child: Text(
                value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userJson = ApiService.user;
    final user = userJson != null ? User.fromJson(userJson) : null;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Personal Info")),
        body: const Center(child: Text("No user data found")),
      );
    } else
      return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Color(0xFFDEF3FD),
            title: const Text(
              "Personal Information",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            iconTheme: IconThemeData(
              color: Colors.black, ),
            centerTitle: true,
          ),
          body:Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFDEF3FD), Color(0xFFF0DEFD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
          children: [
            SizedBox(height: 10,),
            // Profile Header
            CircleAvatar(
              radius: 45,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: user.profilePicture != null
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null
                  ? Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.email,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 30,),
            buildSection(
              icon: Icons.person,
              title: "Basic Information",
              children: [
                buildInfoRow("First Name", user.firstName!= null? user.firstName :"John"),
                buildInfoRow("Last Name", user.lastName!= null ? user.lastName :"Doe"),
                buildInfoRow("Email", user.email!= null ? user.email :"john.doe@example.com"),
                buildInfoRow("Phone Number", user.phoneNumber!= null ? "user.phoneNumber" : "+91 6792727182"),
              ],
            ),
            buildSection(
              icon: Icons.cake,
              title: "Personal Details",
              children: [
                buildInfoRow("Date of Birth", user.dateOfBirth != null
                    ? "${user.dateOfBirth!.toLocal()}".split(' ')[0]
                    : "January 15, 2000"),
                buildInfoRow("Gender", user.gender != null? "${user.gender}": "Male"),
              ],
            ),
            buildSection(
              icon: Icons.account_circle,
              title: "Account Information",
              children: [
                buildInfoRow("User ID", user.id!= null ? user.id:"USR-2023-7845"),
                Row(
                  children: [
                    const SizedBox(
                        width: 120,
                        child: Text("Email Status",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey))),
                    Expanded(child:
                    user.isEmailVerified == true
                        ? Row(
                      children: const [
                        Icon(Icons.verified, color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text("Verified",
                            style: TextStyle(
                                color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    )
                        : Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                        SizedBox(width: 4),
                        Text("Unverified",
                            style: TextStyle(
                                color: Colors.orange, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          child: const Text("Verify Now",
                              style: TextStyle(fontSize: 10)),
                        )
                      ],
                    )
                    )

                  ],
                ),
                Row(
                  children: [
                    const SizedBox(
                        width: 120,
                        child: Text("Phone Status",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey))),
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    const Text("Unverified",
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {

                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text("Verify Now",
                          style: TextStyle(fontSize: 10)),
                    )
                  ],
                ),
                buildInfoRow("Created On", user.createdAt!= null ? DateFormat('MMM dd, yyyy').format(user.updatedAt)
                    :"Mar 12, 2023"),
                buildInfoRow("Last Updated", user.updatedAt!=null? DateFormat('MMM dd, yyyy').format(user.updatedAt) : "Jun 24, 2023"),
              ],
            ),
            buildSection(
              icon: Icons.info,
              title: "Additional Information",
              children: [
                buildInfoRow("User Profile", user.profile!=null ? "${user.profile}" :"Profile info"),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text(
                        "User Roles",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Text(
                          user.roles != null && user.roles!.isNotEmpty
                              ? user.roles!.join(", ")
                              : "No roles mentioned",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          )
                        )
                    )
                        ],
                      ),
                  ],
            ),
          ],
        ),
      ),
          ),
    );
  }
}



