# Procurement Management System Quick Start Guide

**Version:** 1.0  
**Date:** September 11, 2025  
**Developer:** Laith Alskaf (laithalskaf@gmail.com)

## Overview

The Procurement Management System is an integrated application that helps you create, track, and manage purchase orders efficiently. The application supports a complete purchase order cycle from creation to final approval and execution.

## Quick Start Steps

### 1. Login

1. Open the Procurement Management application on your device
2. Enter your provided email and password
3. Click the "Login" button

![Login Screen](./screenshots/login_screen.png)
*Illustration: Login Screen - Take a screenshot of the login screen showing email and password fields and login button*

### 2. Create a New Purchase Order

1. From the main screen, click on "Purchase Orders" in the side menu
2. Click the "+" (add) button at the bottom right of the screen
3. Fill in the required information:
   - **Department:** Select your department
   - **Request Type:** Purchase or Maintenance
   - **Request Date:** Automatically filled with today's date
   - **Execution Date:** Select the required execution date
   - **Vendor:** Choose from the list (optional at this stage)
   - **Currency:** Select the appropriate currency
   - **Notes:** Add any necessary notes

4. Add requested items:
   - Click the "Add Item" button
   - Select an item from the list or enter a new name
   - Specify quantity and unit
   - Enter price (optional)
   - Repeat to add more items

5. Attach documents (optional):
   - Click the "Attach File" button
   - Select a file from your device

6. Click "Save as Draft" to keep the order for later editing, or "Submit for Review" to send it to the Assistant Manager

![Create Purchase Order](./screenshots/create_order.png)
*Illustration: Create Purchase Order Screen - Take a screenshot of the new order creation screen showing the fields mentioned above*

### 3. Track Order Status

1. From the side menu, click on "Purchase Orders"
2. You'll see a list of all your orders with their current status
3. Click on any order to view its details
4. On the details page, you can:
   - See the current status of the order
   - View the approval history and actions
   - Read notes added by reviewers
   - Add new notes (if permitted)
   - Edit the order (if it's in draft or rejected status)

![Order Details](./screenshots/order_details.png)
*Illustration: Order Details Screen - Take a screenshot of the order details screen showing order information and status*

## Order Status Indicators

| Status | Description | Color Indicator |
|--------|-------------|-----------------|
| Draft | Order is being prepared and not yet submitted | Gray |
| Under Assistant Review | Order submitted and awaiting Assistant Manager review | Orange |
| Under Manager Review | Assistant approved and awaiting Manager review | Blue |
| Under Finance Review | Manager approved and awaiting Finance review | Orange |
| Under GM Review | Finance approved and awaiting General Manager review | Blue |
| In Progress | Approved and being processed | Yellow |
| Completed | Order successfully fulfilled | Green |
| Rejected | Order was rejected (reason can be seen in details) | Red |

## Notifications

- You will receive notifications when your orders change status
- Access notifications by clicking the bell icon in the top bar
- Click on any notification to go directly to the related order

## Support and Help

If you encounter any issues or have questions, please contact:
- Support team: support@sabbagh.com
- Phone: +963-xx-xxxxxxx
- Working hours: 9:00 AM - 5:00 PM (Sunday - Thursday)