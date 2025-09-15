import 'package:flutter/material.dart';
import 'package:Soulene/shared/models/user_model.dart';

class HealthProfilePage extends StatelessWidget {
  final UserProfile? user;

  const HealthProfilePage({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Color(0xFFDEF3FD),
          title: const Text(
            "Health Profile",
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
          child:SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Top Health Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Height",
                    user?.height != null ? "${user!.height} cm" : "175 cm",
                    Icons.height, Colors.indigo),
                _buildStatCard("Weight",
                    user?.weight != null ? "${user!.weight} kg" : "68 kg",
                    Icons.monitor_weight, Colors.teal),
                _buildStatCard("Blood Type",
                    user?.bloodType ?? "O+",
                    Icons.bloodtype, Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            /// Medical Info
            SectionCard(
              title: "Medical Information",
              children: [
                _buildInfoRow(Icons.warning_amber_rounded, "Allergies",
                    (user?.allergies?.isNotEmpty ?? false)
                        ? user!.allergies!.join(", ")
                        : "Peanuts, Shellfish"),
                _buildInfoRow(Icons.medication, "Medications",
                    (user?.medications?.isNotEmpty ?? false)
                        ? user!.medications!.join(", ")
                        : "Lisinopril 10mg, Vitamin D"),
                _buildInfoRow(Icons.favorite, "Medical Conditions",
                    (user?.medicalConditions?.isNotEmpty ?? false)
                        ? user!.medicalConditions!.join(", ")
                        : "Mild hypertension, Seasonal allergies"),
              ],
            ),

            /// Emergency Contact
            SectionCard(
              title: "Emergency Contact",
              children: [
                _buildInfoRow(Icons.person, "Name",
                    user?.emergencyContactName != null && user!.emergencyContactName!.isNotEmpty
                        ? user!.emergencyContactName! :  "Sarah Johnson"),
                _buildInfoRow(Icons.phone, "Phone",
                    user?.emergencyContactPhone != null && user!.emergencyContactPhone!.isNotEmpty
                        ? user!.emergencyContactPhone! : "+1 (555) 123-4567"),
              ],
            ),

            /// Wellness Goals
            SectionCard(
              title: "Wellness Goals",
              children: [
                _buildInfoRow(Icons.fitness_center, "Fitness Goals",
                    user?.fitnessGoals != null && user!.fitnessGoals!.isNotEmpty
                        ? "${user!.fitnessGoals!}" :
                        "Run 5k three times per week, strength training twice weekly"),

                _buildInfoRow(Icons.self_improvement, "Mental Health Goals",
                    user?.mentalHealthGoals != null && user!.mentalHealthGoals!.isNotEmpty
                        ? "${user!.mentalHealthGoals!}" :
                        "Daily meditation for 10 minutes, weekly journaling..."),
              ],
            ),
          ],
        ),
      ),
        ),
    );
  }

  /// Widget builders
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }


  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final int previewCount; // how many items to show before expanding

  const SectionCard({
    Key? key,
    required this.title,
    required this.children,
    this.previewCount = 2,
  }) : super(key: key);

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Show limited children when collapsed
    final visibleChildren = isExpanded
        ? widget.children
        : widget.children.take(widget.previewCount).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
          const SizedBox(height: 12),

          ...visibleChildren,

          // See more button if more items exist
          if (widget.children.length > widget.previewCount)
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => setState(() => isExpanded = !isExpanded),
                child: Text(
                  isExpanded ? "See less" : "See more",
                  style: const TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
