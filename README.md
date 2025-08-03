# FlowRecordDisplay

A powerful Lightning Web Component (LWC) that dynamically renders Salesforce records using FlexiPage layouts in Flows and on record pages. This component provides a flexible, metadata-driven approach to displaying and editing records with full support for field visibility rules and custom configurations.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [In Salesforce Flows](#in-salesforce-flows)
  - [On Lightning Record Pages](#on-lightning-record-pages)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

FlowRecordDisplay bridges the gap between Salesforce's powerful FlexiPage layouts and Flow screens. It allows you to:

- Display records using existing page layouts without recreating fields
- Maintain consistency between record pages and flow screens
- Support complex field visibility rules
- Enable both read-only and edit modes
- Handle record creation and updates seamlessly

## Features

### Core Features

- **Dynamic Layout Rendering**: Automatically renders forms based on FlexiPage metadata
- **Field Visibility Rules**: Supports complex visibility rules with boolean filters
- **Flow Integration**: Seamlessly integrates with Salesforce Flows
- **Edit & Read Modes**: Toggle between view and edit modes
- **Default Values**: Set default field values via component attributes
- **Field Exclusion**: Exclude specific fields from the layout
- **Performance Optimized**: Implements caching to minimize API calls

### Advanced Features

- **Custom Property Editor (CPE)**: Advanced configuration interface for Flow Builder
- **Metadata Caching**: Transaction-level and persistent caching for improved performance
- **Platform Events**: Real-time cache refresh capabilities
- **Multi-Object Support**: Works with any standard or custom object
- **Field-Level Security**: Respects user permissions and field accessibility

## Installation

### Prerequisites

- Salesforce DX CLI
- Node.js (v14 or higher)
- Git

### Setup Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/Marceswan/FlowRecordDisplay.git
   cd FlowRecordDisplay
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Authorize your Salesforce org**

   ```bash
   sf org login web -a myorg
   ```

4. **Deploy to your org**

   ```bash
   sf project deploy start
   ```

5. **Assign permissions**
   ```bash
   sf org assign permset -n FlowRecordDisplay_User
   ```

## Usage

### In Salesforce Flows

1. **Add to Screen Element**
   - In Flow Builder, add a Screen element
   - Search for "FlexiPage Record Form" in the components list
   - Drag it onto your screen

2. **Configure the Component**
   - **Record ID**: Bind to a record variable or ID
   - **Object API Name**: Specify the object type (e.g., "Account", "Opportunity")
   - **FlexiPage Name**: Select the page layout to use
   - **Mode**: Choose between "view" or "edit"

3. **Optional Settings**
   - **Default Values**: Set initial field values (format: "Field1:Value1,Field2:Value2")
   - **Excluded Fields**: List fields to hide (comma-separated)
   - **Show Only Specified Fields**: Display only certain fields

### On Lightning Record Pages

1. **Edit Lightning Record Page**
   - Navigate to a record page
   - Click the gear icon and select "Edit Page"

2. **Add Component**
   - Find "FlexiPage Record Form" in the component list
   - Drag to desired location on the page

3. **Configure Properties**
   - The component automatically detects the current record
   - Select the FlexiPage layout to use
   - Configure display options as needed

## Configuration

### Component Properties

| Property             | Type    | Description                     | Default           |
| -------------------- | ------- | ------------------------------- | ----------------- |
| `recordId`           | String  | ID of the record to display     | Current record ID |
| `objectApiName`      | String  | API name of the object          | Auto-detected     |
| `flexiPageName`      | String  | Developer name of the FlexiPage | Required          |
| `mode`               | String  | Display mode: "view" or "edit"  | "view"            |
| `defaultFieldValues` | String  | Default values for fields       | Empty             |
| `excludedFields`     | String  | Fields to exclude from display  | Empty             |
| `showOnlyFields`     | String  | Show only these fields          | Empty             |
| `columns`            | Integer | Number of columns (1 or 2)      | 2                 |

### Setting Default Values

Default values can be set using comma or semicolon-separated key-value pairs:

```
AccountName:Acme Corp,Industry:Technology,AnnualRevenue:1000000
```

### Excluding Fields

Specify fields to exclude as a comma-separated list:

```
CreatedById,LastModifiedById,SystemModstamp
```

## Architecture

### Component Structure

```
force-app/
├── main/
│   └── default/
│       ├── classes/
│       │   ├── FlexiPageMetadataService.cls       # Metadata retrieval service
│       │   ├── FlexiPageCacheService.cls          # Caching implementation
│       │   ├── FieldSelectorController.cls        # Field metadata provider
│       │   └── FlexiPageCacheAdminController.cls  # Cache management
│       ├── lwc/
│       │   ├── flexipageRecordForm/               # Main component
│       │   ├── flexipageRecordFormCPE/            # Custom Property Editor
│       │   └── fsc_flowCombobox/                  # Flow variable selector
│       ├── objects/
│       │   ├── FlexiPage_Cache__c/                # Cache storage object
│       │   └── FlexiPage_Cache_Refresh__e/        # Platform event
│       └── triggers/
│           └── FlexiPageCacheRefreshTrigger.trigger
```

### Key Classes

#### FlexiPageMetadataService

- Retrieves FlexiPage metadata using Salesforce APIs
- Handles metadata parsing and transformation
- Manages API versioning

#### FlexiPageCacheService

- Implements multi-level caching strategy
- Transaction-level cache using static maps
- Persistent cache using custom objects
- Platform event-driven cache refresh

#### flexipageRecordForm LWC

- Main component for rendering records
- Handles field visibility rules
- Manages record updates and validation

## Development

### Local Development Setup

1. **Install development dependencies**

   ```bash
   npm install --save-dev
   ```

2. **Run linting**

   ```bash
   npm run lint
   ```

3. **Run tests**

   ```bash
   npm run test:unit
   ```

4. **Watch mode for tests**
   ```bash
   npm run test:unit:watch
   ```

### Code Standards

- ESLint configuration for code quality
- Prettier for code formatting
- Jest for unit testing
- Minimum 90% code coverage requirement

### Key Development Commands

```bash
# Lint the code
npm run lint

# Format code with Prettier
npm run prettier

# Run all tests with coverage
npm run test:unit:coverage

# Deploy specific components
sf project deploy start -d force-app/main/default/lwc/flexipageRecordForm
```

## Testing

### Unit Tests

The project includes comprehensive Jest tests for all LWC components:

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:unit:watch

# Generate coverage report
npm run test:unit:coverage
```

### Apex Tests

Run Apex tests with:

```bash
# Run all tests
sf apex run test --test-level RunLocalTests --code-coverage

# Run specific test class
sf apex run test --tests FlexiPageMetadataServiceTest --code-coverage
```

### Manual Testing

1. **Create Test Flow**
   - Create a new Screen Flow
   - Add the FlexiPage Record Form component
   - Configure with test parameters
   - Run in debug mode

2. **Test Scenarios**
   - Record creation with default values
   - Record editing with validation
   - Field visibility rules
   - Multi-column layouts
   - Error handling

## Deployment

### Production Deployment

1. **Validate deployment**

   ```bash
   sf project deploy validate --test-level RunLocalTests
   ```

2. **Deploy with tests**

   ```bash
   sf project deploy start --test-level RunLocalTests
   ```

3. **Post-deployment steps**
   - Assign permission sets to users
   - Configure page layouts
   - Update flows to use the component

### Deployment Best Practices

- Always deploy to sandbox first
- Run all tests before production deployment
- Document any manual configuration steps
- Monitor performance after deployment

## Performance Optimization

### Caching Strategy

The component implements a three-tier caching strategy:

1. **Transaction Cache**: In-memory cache for the current transaction
2. **Platform Cache**: Org-wide cache (if available)
3. **Database Cache**: Custom object storage for persistence

### Best Practices

- Use specific FlexiPage names rather than wildcards
- Minimize the number of fields displayed
- Enable caching for frequently accessed layouts
- Monitor API usage and limits

### Cache Management

```apex
// Clear cache for specific FlexiPage
FlexiPageCacheService.clearCache('Account_Record_Page');

// Clear all cache
FlexiPageCacheService.clearAllCache();

// Refresh cache via platform event
FlexiPageCacheService.publishRefreshEvent('Account_Record_Page');
```

## Troubleshooting

### Common Issues

1. **"FlexiPage not found" error**
   - Verify the FlexiPage developer name is correct
   - Check user permissions for the FlexiPage
   - Ensure the FlexiPage is active

2. **Fields not displaying**
   - Check field-level security
   - Verify field visibility rules
   - Confirm fields exist on the FlexiPage

3. **Performance issues**
   - Enable caching if not already active
   - Reduce the number of fields displayed
   - Check for governor limit warnings

### Debug Mode

Enable debug logging:

```apex
// In Developer Console
System.debug(LoggingLevel.DEBUG, 'FlexiPage Metadata: ' +
    FlexiPageMetadataService.getFlexiPageMetadata('Account_Record_Page'));
```

### Support

For issues and questions:

1. Check existing [GitHub Issues](https://github.com/Marceswan/FlowRecordDisplay/issues)
2. Review the [Wiki](https://github.com/Marceswan/FlowRecordDisplay/wiki)
3. Create a new issue with detailed information

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Review Guidelines

- Ensure all tests pass
- Maintain 90%+ code coverage
- Follow existing code style
- Update documentation as needed
- Add test cases for new features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Salesforce Developer Community
- Contributors and testers
- Flow Screen Components Base Pack team

---

**Note**: This component requires appropriate Salesforce licenses and permissions. Ensure users have access to the objects and fields being displayed.
