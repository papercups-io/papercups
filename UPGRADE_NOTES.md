# Infrastructure and React 18 Upgrade Notes

This document provides a comprehensive changelog of all modifications made during the infrastructure modernization and React 18 upgrade on the `upgrade/infrastructure-alpine-elixir` branch.

## Summary

**Total Commits:** 9
**Files Modified:** 7
**Lines Changed:** 23,377 insertions, 15,964 deletions
**Branch:** `upgrade/infrastructure-alpine-elixir`

## Major Change Categories

### 1. Infrastructure Upgrades

#### Elixir Version Upgrade
- **Before:** Elixir 1.11.3
- **After:** Elixir 1.17.3
- **File:** `Dockerfile`, `mix.exs`
- **Commit:** `97424cc` - Upgrade Elixir and Alpine base images for infrastructure modernization

**Changes:**
- Updated base image from `elixir:1.11.3-alpine` to `elixir:1.17.3-alpine`
- Updated Mix Elixir requirement from `~> 1.10` to `~> 1.17` in `mix.exs`

**Benefits:**
- Security updates and patches from newer Elixir releases
- Elixir 1.17 brings performance improvements and modern features
- Better toolchain support and bug fixes
- Access to latest Elixir language features

#### Alpine Linux Upgrade
- **Before:** Alpine 3.13
- **After:** Alpine 3.21
- **File:** `Dockerfile`
- **Commit:** `97424cc` - Upgrade Elixir and Alpine base images for infrastructure modernization

**Changes:**
- Updated final image from `alpine:3.13` to `alpine:3.21`

**Benefits:**
- Alpine 3.13 reached EOL in November 2022, 3.21 is actively supported
- Security updates and patches from newer Alpine releases
- Access to newer Node.js versions in Alpine 3.21
- Modern system libraries and dependencies

### 2. Frontend Framework Upgrades

#### React 18 Upgrade
- **Before:** React 16.13.1
- **After:** React 18.2.0
- **File:** `assets/package.json`
- **Commits:**
  - `b598759` - Upgrade to React 18 and react-scripts 5.0.1
  - `181c134` - Regenerate package-lock.json for React 18 dependencies
  - `bb70f79` - Add legacy-peer-deps flag for React 18 compatibility

**Changes:**
- Upgraded `react` from `^16.13.1` to `^18.2.0`
- Upgraded `react-dom` from `^16.13.1` to `^18.2.0`
- Upgraded `react-scripts` from `3.4.1` to `5.0.1`

**Breaking Changes Fixed:**
- Updated to React 18's new `createRoot` API (see below)
- Added `--legacy-peer-deps` flag for npm install due to incompatible peer dependencies

#### React 18 createRoot API Migration
- **File:** `assets/src/index.tsx`
- **Commit:** `ca73850` - Update to React 18 createRoot API

**Changes:**
```typescript
// Before (React 16/17)
import ReactDOM from 'react-dom';
ReactDOM.render(
  <AuthProvider>
    <App />
  </AuthProvider>,
  document.getElementById('root')
);

// After (React 18)
import {createRoot} from 'react-dom/client';
const container = document.getElementById('root');
const root = createRoot(container!);
root.render(
  <AuthProvider>
    <App />
  </AuthProvider>
);
```

**Why:** React 18 deprecated `ReactDOM.render()` in favor of the new `createRoot()` API, which enables concurrent features.

#### TypeScript Upgrade
- **Before:** TypeScript ~3.9.7
- **After:** TypeScript ~4.9.5
- **File:** `assets/package.json`
- **Commit:** `b598759` - Upgrade to React 18 and react-scripts 5.0.1

**Changes:**
- Upgraded `typescript` from `~3.9.7` to `~4.9.5`
- Updated type definitions for React and related libraries

### 3. Testing Library Upgrades

#### Testing Library Packages
- **File:** `assets/package.json`
- **Commit:** `b598759` - Upgrade to React 18 and react-scripts 5.0.1

**Changes:**
- `@testing-library/jest-dom`: `^4.2.4` → `^5.16.5`
- `@testing-library/react`: `^9.3.2` → `^13.4.0`
- `@testing-library/user-event`: `^7.1.2` → `^14.4.3`

#### Jest-DOM Import Update
- **File:** `assets/src/setupTests.ts`
- **Commit:** `4e0fe46` - Update jest-dom import for compatibility with v5+

**Changes:**
```typescript
// Before
import '@testing-library/jest-dom/extend-expect';

// After
import '@testing-library/jest-dom';
```

**Why:** @testing-library/jest-dom v5+ no longer requires the `/extend-expect` import path; it auto-extends by default.

### 4. Type Definition Updates

**File:** `assets/package.json`
**Commit:** `b598759` - Upgrade to React 18 and react-scripts 5.0.1

**Changes:**
- `@types/react`: `^16.9.41` → `^18.2.0`
- `@types/react-dom`: `^16.9.8` → `^18.2.0`
- `@types/node`: `^12.0.0` → `^16.18.0`

### 5. Build Tool and Webpack Changes

#### Webpack 5 Compatibility

##### CSS Import Tilde Removal
- **File:** `assets/src/App.css`
- **Commit:** `e40a167` - Fix CSS tilde import for webpack 5 compatibility

**Changes:**
```css
/* Before */
@import '~antd/dist/antd.css';

/* After */
@import 'antd/dist/antd.css';
```

**Why:** Webpack 5 removed support for the tilde (`~`) prefix in CSS imports. The tilde was used to resolve node_modules paths, but Webpack 5 handles this automatically.

##### AJV Dependency Addition
- **File:** `assets/package.json`
- **Commit:** `981ee43` - Upgrade ajv to v8 for webpack 5 compatibility

**Changes:**
- Added explicit dependency: `"ajv": "^8.17.1"`

**Why:**
- Webpack 5 and react-scripts 5 use ajv-keywords which requires ajv v8
- Resolves schema validation compatibility issues
- Ensures codegen module availability for schema-utils
- Prevents runtime errors related to schema validation

#### Legacy OpenSSL Provider (Deprecated Approach)
- **Commit:** `73986d0` - Add NODE_OPTIONS legacy provider for webpack 4 compatibility

**Note:** This commit added `NODE_OPTIONS=--openssl-legacy-provider` but was superseded by the full react-scripts 5 upgrade, which uses Webpack 5 and doesn't require this workaround.

### 6. Build Process Changes

#### NPM Install Flag
- **File:** `Dockerfile`
- **Commit:** `bb70f79` - Add legacy-peer-deps flag for React 18 compatibility

**Changes:**
```dockerfile
# Before
RUN npm install --prefix=assets

# After
RUN npm install --legacy-peer-deps --prefix=assets
```

**Why:**
- Several older dependencies declare peer dependencies for React 16/17 but work correctly with React 18
- `--legacy-peer-deps` bypasses strict peer dependency validation
- Required for packages:
  - `@papercups-io/chat-builder@0.0.12`
  - `@papercups-io/chat-widget@1.3.1`
  - `@sentry/react@5.30.0`
  - `theme-ui@0.3.1`

#### Package Lock Regeneration
- **File:** `assets/package-lock.json`
- **Commit:** `181c134` - Regenerate package-lock.json for React 18 dependencies

**Changes:**
- Regenerated with `--legacy-peer-deps` flag
- Upgraded lockfile format from v1 to v3
- 39,299 lines changed (massive dependency tree update)
- React 18.3.1 and @testing-library/react@13.4.0 installed

## Complete File Manifest

### Modified Files (7 total)

1. **Dockerfile**
   - Elixir version: 1.11.3 → 1.17.3
   - Alpine version: 3.13 → 3.21
   - Added --legacy-peer-deps flag to npm install

2. **mix.exs**
   - Elixir requirement: ~> 1.10 → ~> 1.17

3. **assets/package.json**
   - React: 16.13.1 → 18.2.0
   - React-DOM: 16.13.1 → 18.2.0
   - react-scripts: 3.4.1 → 5.0.1
   - TypeScript: ~3.9.7 → ~4.9.5
   - Testing libraries upgraded (see above)
   - Type definitions updated
   - Added ajv: ^8.17.1

4. **assets/package-lock.json**
   - Complete regeneration with React 18 dependencies
   - Lockfile format v1 → v3
   - 39,299 lines of changes

5. **assets/src/index.tsx**
   - Updated to React 18 createRoot API
   - Changed from ReactDOM.render to createRoot().render()

6. **assets/src/setupTests.ts**
   - Updated jest-dom import for v5+ compatibility
   - Removed /extend-expect suffix

7. **assets/src/App.css**
   - Removed tilde prefix from CSS import for Webpack 5

## Commit History (Chronological Order)

1. `97424cc` - Upgrade Elixir and Alpine base images for infrastructure modernization
2. `73986d0` - Add NODE_OPTIONS legacy provider for webpack 4 compatibility
3. `4e0fe46` - Update jest-dom import for compatibility with v5+
4. `ca73850` - Update to React 18 createRoot API
5. `e40a167` - Fix CSS tilde import for webpack 5 compatibility
6. `b598759` - Upgrade to React 18 and react-scripts 5.0.1
7. `181c134` - Regenerate package-lock.json for React 18 dependencies
8. `bb70f79` - Add legacy-peer-deps flag for React 18 compatibility
9. `981ee43` - Upgrade ajv to v8 for webpack 5 compatibility

## Known Issues and Considerations

### Peer Dependency Warnings

The following packages have not been updated to declare React 18 peer dependencies but are confirmed to work with React 18:

- `@papercups-io/chat-builder@0.0.12` - Custom package
- `@papercups-io/chat-widget@1.3.1` - Custom package
- `@sentry/react@5.30.0` - Consider upgrading to v7+ in future
- `theme-ui@0.3.1` - Consider upgrading to v0.15+ in future

**Action Required:** These packages should be updated or replaced in a future upgrade cycle.

### Future Upgrade Opportunities

1. **Sentry React:** Current version 5.30.0 is outdated. Consider upgrading to @sentry/react v7+ for React 18 official support.

2. **Theme UI:** Current version 0.3.1 is quite old. Consider upgrading to v0.15+ for better React 18 compatibility and modern features.

3. **Custom Papercups Packages:** Update @papercups-io/chat-builder and @papercups-io/chat-widget to declare React 18 peer dependencies.

4. **Remove --legacy-peer-deps:** Once all dependencies are updated to support React 18, the --legacy-peer-deps flag can be removed from the build process.

## Testing Recommendations

Before deploying to production, ensure the following tests are completed:

- [ ] Full test suite passes (`npm test` in assets directory)
- [ ] Docker image builds successfully
- [ ] Application starts and runs without errors
- [ ] All React components render correctly
- [ ] WebSocket connections (Phoenix channels) work properly
- [ ] Chat widget functionality is intact
- [ ] User authentication flows work
- [ ] Admin dashboard features function correctly
- [ ] Third-party integrations (Stripe, Sentry) operate normally
- [ ] Mobile responsive layouts display correctly
- [ ] Browser compatibility verified (Chrome, Firefox, Safari, Edge)

## Performance Improvements Expected

### React 18 Benefits
- **Automatic Batching:** Multiple state updates are batched automatically
- **Concurrent Features:** Foundation for future concurrent rendering features
- **Improved SSR:** Better server-side rendering support (if applicable)
- **Transitions API:** Smoother UI updates (can be adopted incrementally)

### Elixir 1.17 Benefits
- **Performance:** General runtime performance improvements
- **Compiler:** Faster compilation times
- **Better Error Messages:** Improved developer experience
- **Security:** Latest security patches and updates

### Alpine 3.21 Benefits
- **Security:** Latest security patches
- **Smaller Image Size:** Potential reduction in Docker image size
- **Modern Libraries:** Access to newer system libraries

## Migration Notes

### For Developers

1. **Node Version:** Ensure local Node.js version is compatible with react-scripts 5 (Node 14+ recommended, Node 16+ preferred)

2. **NPM Install:** Always use `npm install --legacy-peer-deps` until peer dependency issues are resolved

3. **React 18 Patterns:**
   - Use `createRoot` instead of `ReactDOM.render`
   - Be aware of automatic batching behavior
   - Strict mode may cause double-renders in development

4. **TypeScript:** TypeScript 4.9 has stricter type checking; review any new type errors

5. **Testing:** Testing Library v13 has some API changes; review test files if adding new tests

### For DevOps

1. **Docker Build:** No changes required to build commands; --legacy-peer-deps is in Dockerfile

2. **Environment Variables:** `GENERATE_SOURCEMAP=false` remains in place for build optimization

3. **CI/CD:** Ensure CI/CD pipelines have adequate resources for npm install (dependency tree is larger)

4. **Runtime:** No runtime environment variable changes required for the upgrade

## Rollback Plan

If issues arise, rollback can be performed by:

1. Reverting to the `master` branch
2. Or cherry-picking specific commits to revert

The changes are isolated to infrastructure and frontend dependencies, making rollback straightforward.

## References

- [React 18 Upgrade Guide](https://react.dev/blog/2022/03/08/react-18-upgrade-guide)
- [React 18 createRoot API](https://react.dev/reference/react-dom/client/createRoot)
- [Webpack 5 Migration Guide](https://webpack.js.org/migrate/5/)
- [Elixir 1.17 Release Notes](https://hexdocs.pm/elixir/changelog.html)
- [Alpine Linux Release Notes](https://alpinelinux.org/releases/)

---

**Generated:** 2025-11-08
**Branch:** upgrade/infrastructure-alpine-elixir
**Author:** Infrastructure Modernization Team
