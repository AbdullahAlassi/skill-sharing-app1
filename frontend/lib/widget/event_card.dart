import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({Key? key, required this.event, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image or placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child:
                  event.image != null
                      ? Image.network(
                        event.image!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        height: 120,
                        width: double.infinity,
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          event.isVirtual ? Icons.videocam : Icons.event,
                          size: 50,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(event.date),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Event title
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Event location
                  Row(
                    children: [
                      Icon(
                        event.isVirtual ? Icons.videocam : Icons.location_on,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Event organizer
                  if (event.organizerName != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'By ${event.organizerName}',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          event.isUserRegistered || event.isFull ? null : onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            event.isUserRegistered
                                ? AppTheme.successColor
                                : AppTheme.primaryColor,
                        disabledBackgroundColor: AppTheme.textSecondaryColor,
                      ),
                      child: Text(
                        event.isUserRegistered
                            ? 'Registered'
                            : event.isFull
                            ? 'Event Full'
                            : 'Register',
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
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('EEE, MMM d, yyyy • h:mm a');
    return formatter.format(date);
  }
}
