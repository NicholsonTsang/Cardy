# Cardy CMS - Project Documentation

## Business Overview

**Cardy CMS** is a comprehensive content management system for designing, managing, and issuing physical smart cards with QR code activation capabilities. The platform enables businesses and individuals to create digital business cards, promotional cards, or information cards that can be activated by end-users through QR code scanning.

### Business Model

The platform operates on a **card issuance and printing service model**:

1. **Card Design Phase**: Users create and customize card designs with content, images, and AI-powered features
2. **Content Management**: Users can add multiple content items (text, images, links) organized in series
3. **Card Issuance**: Cards are issued in batches (typically 100 cards per batch) with unique activation codes
4. **Physical Printing**: Users can request physical card printing at $2 USD per card
5. **End-User Activation**: Recipients scan QR codes to activate and view card content

### Target Market

- **Small Businesses**: Digital business cards with contact information and services
- **Event Organizers**: Promotional cards for events, conferences, or marketing campaigns
- **Educational Institutions**: Student ID cards or information cards
- **Healthcare Providers**: Patient information or appointment cards
- **Real Estate Agents**: Property showcase cards with virtual tours

## Core Features

### Card Management System
- **Card Creation & Editing**: Dynamic card design with images, descriptions, and content
- **Content Management**: Hierarchical content structure with categories and items
- **QR Code Integration**: Automatic QR code generation for card access
- **AI Integration**: Optional conversational AI for enhanced user interaction

### 1. Card Design & Management
- **Visual Card Designer**: Create cards with custom images, descriptions, and branding
- **QR Code Positioning**: Configurable QR code placement (Top Left, Top Right, Bottom Left, Bottom Right)
- **AI Integration**: Conversation AI capabilities with custom prompts
- **Content Render Modes**: Support for different content organization patterns

### 2. Content Management System
- **Hierarchical Content**: Organize content in series (categories) and items
- **Rich Media Support**: Images, text, and multimedia content
- **Content Ordering**: Drag-and-drop content organization
- **AI Metadata**: Enhanced content with AI-powered interactions

### 3. Card Issuance & Batch Management
- **Batch Issuance**: Issue cards in configurable quantities (default: 10-100 cards)
- **Unique Activation Codes**: Each card gets a unique activation code
- **Batch Tracking**: Monitor issued, activated, and pending cards
- **Batch Status Management**: Enable/disable batches as needed

### 4. Print Request System
- **Print Ordering**: Request physical card printing with shipping details
- **Cost Management**: $2 USD per card pricing model
- **Status Tracking**: Track print requests from submission to completion
- **Admin Workflow**: Payment processing and shipping coordination

### 5. Analytics & Reporting
- **Activation Metrics**: Track card activation rates and usage
- **Batch Statistics**: Monitor performance across different batches
- **User Engagement**: Analyze content interaction patterns

## Technical Architecture

### Frontend Stack
- **Framework**: Vue.js 3 with Composition API
- **UI Library**: PrimeVue 4.3.3 with Aura theme
- **Styling**: Tailwind CSS 3.4.17 with custom design system
- **State Management**: Pinia for reactive state management
- **Routing**: Vue Router 4 with authentication guards
- **Build Tool**: Vite 6.2.4 with TypeScript support

### Backend Infrastructure
- **Database**: PostgreSQL with Supabase
- **Authentication**: Supabase Auth with email/password and Google OAuth
- **Storage**: Supabase Storage for card images and media
- **API**: PostgreSQL stored procedures with Row Level Security (RLS)
- **Real-time**: Supabase real-time subscriptions for live updates

### Database Schema

#### Core Tables
1. **cards**: Card design templates and configurations
2. **content_items**: Hierarchical content structure
3. **card_batches**: Batch management for card issuance
4. **issue_cards**: Individual issued cards with activation codes
5. **print_requests**: Physical printing requests and status tracking

#### Key Relationships
- Cards → Content Items (1:many)
- Cards → Card Batches (1:many)
- Card Batches → Issue Cards (1:many)
- Card Batches → Print Requests (1:many)

### Security Model

#### Authentication & Authorization
- **Supabase Auth**: Secure user authentication with email verification
- **Row Level Security (RLS)**: Database-level access control
- **User Isolation**: Users can only access their own cards and data
- **API Security**: Stored procedures with security invoker rights

#### Data Protection
- **Encrypted Storage**: All sensitive data encrypted at rest
- **Secure File Upload**: Image uploads with validation and virus scanning
- **HTTPS Only**: All communications encrypted in transit
- **Input Validation**: Comprehensive server-side validation

## Application Structure

### Directory Organization
```
src/
├── components/           # Reusable Vue components
│   ├── Card.vue/        # Card-related components
│   ├── CardContent/     # Content management components
│   ├── CardIssurance.vue # Card issuance and batch management
│   └── MyDialog.vue     # Reusable dialog component
├── views/               # Page-level components
│   ├── Dashboard/
│   │   ├── CardIssuer/
│   │   │   ├── MyCards.vue      # Card management dashboard
│   │   │   ├── IssuedCards.vue  # Issued cards overview
│   │   │   └── Profile.vue      # User profile management
│   ├── SignIn.vue       # Authentication pages
│   ├── SignUp.vue
│   └── CardCreateEditForm.vue  # Card creation and editing forms
├── stores/              # Pinia state management
│   ├── auth.ts          # Authentication state
│   ├── card.ts          # Card management state
│   ├── contentItem.ts   # Content management state
│   └── issuedCard.ts    # Card issuance state
├── router/              # Vue Router configuration
├── layouts/             # Layout components
├── lib/                 # Utility libraries
└── assets/              # Static assets
```

### Component Architecture

#### Card Management Flow
1. **MyCards.vue**: Main dashboard with card list and tabbed interface
2. **CardCreateEditForm.vue**: Card creation and editing forms
3. **CardView.vue**: Read-only card display with actions
4. **CardContent.vue**: Content management interface
5. **CardIssurance.vue**: Batch issuance and print management

#### State Management Pattern
- **Centralized Stores**: Pinia stores for each domain (auth, cards, content, issuance)
- **Reactive Updates**: Real-time UI updates through reactive state
- **Error Handling**: Consistent error handling with toast notifications
- **Loading States**: Proper loading indicators throughout the application

## User Workflows

### 1. Card Creation Workflow
1. User signs in to the CMS
2. Navigate to "My Cards" section
3. Click "Create New Card" button
4. Fill in card details (name, description, image)
5. Configure QR code position and AI settings
6. Save card design
7. Add content items to the card
8. Organize content in series and items

### 2. Card Issuance Workflow
1. Select a card design
2. Navigate to "Card Issuance" tab
3. Click "Issue New Batch" button
4. Specify quantity (default: 10 cards)
5. System generates unique activation codes
6. Batch is created with "Enabled" status
7. Individual cards are available for activation

### 3. Print Request Workflow
1. Select an enabled batch
2. Click "Request Printing" button
3. Enter shipping address details
4. Submit print request ($2 USD per card)
5. Admin receives notification for payment processing
6. Status updates: Submitted → Payment Pending → Processing → Shipped → Completed

### 4. End-User Activation Workflow
1. End-user receives physical card with QR code
2. Scan QR code with mobile device
3. Redirected to activation URL: `app.cardy.com/issuedcard/{cardId}/{activationCode}`
4. Card content is displayed to the user
5. Card status changes from "Pending" to "Active"

## API Endpoints (Stored Procedures)

### Card Management
- `get_user_cards()`: Retrieve all cards for authenticated user
- `create_card(...)`: Create new card design
- `update_card(...)`: Update existing card
- `delete_card(card_id)`: Delete card and related data
- `get_card_by_id(card_id)`: Get specific card details

### Content Management
- `get_content_items(card_id)`: Get all content for a card
- `create_content_item(...)`: Add new content item
- `update_content_item(...)`: Update content item
- `delete_content_item(item_id)`: Remove content item
- `reorder_content_items(...)`: Update content order

### Card Issuance
- `issue_card_batch(...)`: Create new batch of cards
- `get_card_batches(card_id)`: Get all batches for a card
- `get_issued_cards_with_batch(card_id)`: Get individual issued cards
- `toggle_card_batch_disabled_status(...)`: Enable/disable batch
- `activate_issued_card(...)`: Activate individual card

### Print Management
- `request_card_printing(...)`: Submit print request
- `get_print_requests_for_batch(batch_id)`: Get print requests for batch

## Deployment & Infrastructure

### Development Environment
- **Local Development**: Vite dev server with hot reload
- **Database**: Local Supabase instance or cloud development project
- **Environment Variables**: `.env` file with Supabase credentials

### Production Environment
- **Frontend Hosting**: Static site deployment (Vercel, Netlify, or similar)
- **Database**: Supabase cloud with production configuration
- **CDN**: Global content delivery for optimal performance
- **Monitoring**: Error tracking and performance monitoring

### Environment Configuration
```env
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
VITE_SUPABASE_CARD_STORAGE_BUCKET=cards
```

## Performance Considerations

### Frontend Optimization
- **Code Splitting**: Route-based code splitting with Vue Router
- **Image Optimization**: Compressed images with lazy loading
- **Bundle Size**: Tree-shaking and minimal dependencies
- **Caching**: Browser caching for static assets

### Database Optimization
- **Indexing**: Strategic indexes on frequently queried columns
- **Query Optimization**: Efficient stored procedures
- **Connection Pooling**: Supabase connection management
- **RLS Performance**: Optimized Row Level Security policies

## Security Considerations

### Data Privacy
- **GDPR Compliance**: User data protection and deletion rights
- **Data Minimization**: Collect only necessary user information
- **Audit Logging**: Track data access and modifications
- **Backup Strategy**: Regular encrypted backups

### Application Security
- **Input Sanitization**: Prevent XSS and injection attacks
- **File Upload Security**: Validate file types and scan for malware
- **Rate Limiting**: Prevent abuse and DoS attacks
- **Session Management**: Secure session handling with Supabase Auth

## Future Enhancements

### Planned Features
1. **Advanced Analytics**: Detailed usage analytics and reporting
2. **Template Marketplace**: Pre-designed card templates
3. **Bulk Operations**: Batch operations for content management
4. **API Integration**: Third-party integrations (CRM, email marketing)
5. **Mobile App**: Native mobile app for card management
6. **White Label**: Custom branding for enterprise customers

### Technical Improvements
1. **Progressive Web App**: PWA capabilities for offline access
2. **Real-time Collaboration**: Multi-user editing capabilities
3. **Advanced Search**: Full-text search across cards and content
4. **Automated Testing**: Comprehensive test suite
5. **Performance Monitoring**: Advanced performance tracking

## Support & Maintenance

### Documentation
- **User Guide**: Comprehensive user documentation
- **API Documentation**: Developer API reference
- **Troubleshooting**: Common issues and solutions

### Monitoring & Alerts
- **Uptime Monitoring**: 24/7 system availability monitoring
- **Error Tracking**: Real-time error reporting and alerting
- **Performance Metrics**: Response time and throughput monitoring

### Backup & Recovery
- **Automated Backups**: Daily database backups
- **Disaster Recovery**: Multi-region backup strategy
- **Data Retention**: Configurable data retention policies

---

*This documentation is maintained alongside the codebase and should be updated with any significant changes to the system architecture or business logic.* 