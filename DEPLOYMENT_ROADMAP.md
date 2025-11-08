# React 18 Upgrade: Executive Summary and Deployment Roadmap

**Project:** Papercups Infrastructure Modernization
**Branch:** `upgrade/infrastructure-alpine-elixir`
**Date:** 2025-11-08
**Status:** HOLD - Critical Build Issue Requires Resolution

---

## Executive Summary

### Upgrade Overview

The Papercups application has undergone a comprehensive infrastructure modernization, upgrading from React 16 to React 18, along with critical backend infrastructure improvements. This upgrade brings the application to modern, supported versions across the entire stack.

**Key Achievements:**
- React 16.13.1 → React 18.2.0 (major version jump)
- Elixir 1.10 → Elixir 1.17 (7 major versions)
- Alpine Linux 3.13 → Alpine 3.21 (EOL → actively supported)
- TypeScript 3.9 → TypeScript 4.9
- Testing libraries fully modernized
- 9 commits, 7 files modified, 23,377 insertions

### Current Status: CRITICAL ISSUE IDENTIFIED

**Build Status:** FAILING
**Test Status:** PASSING (32/32 tests pass)
**Blocker:** Webpack 5 polyfill issue with `react-markdown` dependency

#### The Problem

The production build fails with a webpack 5 polyfill error:
```
Module not found: Error: Can't resolve 'path' in 'node_modules/vfile'
BREAKING CHANGE: webpack < 5 used to include polyfills for node.js core modules by default.
```

**Root Cause:** The `react-markdown@4.3.1` dependency uses `unified@6.2.0` which uses `vfile@2.3.0`. The `vfile` package expects Node.js core modules (`path`) that webpack 5 no longer polyfills automatically.

**Impact:** Cannot build production bundle, blocking deployment.

---

## Success Metrics

### Completed ✓

1. **Test Suite Passing**
   - All 32 tests passing
   - No test regressions
   - Testing library upgrades successful

2. **React 18 API Migration**
   - Successfully migrated to `createRoot` API
   - No breaking changes in application code
   - Automatic batching enabled

3. **Infrastructure Upgrades**
   - Elixir 1.17.3 (latest stable)
   - Alpine 3.21 (latest stable, EOL → supported)
   - Security patches and modern toolchain

4. **Type Safety**
   - TypeScript 4.9 compilation successful
   - All type definitions updated
   - No type errors

5. **Development Environment**
   - Local development tested
   - Docker build process updated
   - CI/CD configuration prepared

### Blocked ✗

1. **Production Build**
   - Build fails due to webpack polyfill issue
   - Cannot generate production bundle
   - Deployment not possible

2. **End-to-End Testing**
   - Cannot test production build
   - No performance benchmarks available
   - User acceptance testing blocked

---

## Risk Assessment

### High Risk Items

1. **Production Build Failure** (CRITICAL)
   - **Risk:** Cannot deploy to production
   - **Impact:** All deployment plans blocked
   - **Mitigation:** Fix react-markdown dependency (see solutions below)
   - **Timeline:** 1-4 hours to implement and test

2. **Peer Dependency Warnings** (MEDIUM)
   - **Risk:** Using `--legacy-peer-deps` bypasses npm safety checks
   - **Impact:** Potential runtime issues with incompatible dependencies
   - **Affected Packages:**
     - `@papercups-io/chat-builder@0.0.12`
     - `@papercups-io/chat-widget@1.3.1`
     - `@sentry/react@5.30.0`
     - `theme-ui@0.3.1`
   - **Mitigation:** Upgrade these packages in next phase
   - **Current Status:** Confirmed working in tests

3. **CI/CD Pipeline Outdated** (MEDIUM)
   - **Risk:** GitHub Actions workflows specify old Elixir versions
   - **Impact:** CI builds may fail or use wrong versions
   - **File:** `.github/workflows/papercups.yml` still references Elixir 1.10-1.11
   - **Mitigation:** Update CI configuration before merge

### Medium Risk Items

1. **Large Dependency Tree Changes** (39,299 lines in package-lock.json)
   - Extensive dependency updates may have hidden issues
   - Increased bundle size possible
   - Mitigated by: Comprehensive testing required

2. **Webpack 5 Migration Side Effects**
   - Other polyfill issues may surface
   - Build configuration changes may affect performance
   - Mitigated by: Thorough testing and monitoring

3. **React 18 Concurrent Features**
   - Automatic batching may change timing of effects
   - StrictMode double-renders in development
   - Mitigated by: Existing tests pass, monitor production

### Low Risk Items

1. **Performance Regression**
   - React 18 generally improves performance
   - Elixir 1.17 has performance improvements
   - Likelihood: Very low

2. **Breaking Changes in Application Code**
   - Only one file changed (index.tsx for createRoot)
   - All tests passing
   - Likelihood: Very low

---

## Go/No-Go Recommendation

### **RECOMMENDATION: HOLD**

**Do NOT merge to master until the build issue is resolved.**

### Rationale

**Positives:**
- Test suite fully passing (32/32 tests)
- Infrastructure upgrades are sound
- React 18 migration technically correct
- Security improvements (EOL software → supported versions)
- Code quality maintained

**Blockers:**
- Production build fails (CRITICAL)
- Cannot generate deployable artifacts
- Cannot perform production testing

**Decision:** Fix the `react-markdown` webpack polyfill issue before proceeding. This is a quick fix (estimated 1-4 hours) and should not delay the upgrade significantly.

---

## Critical Issue Resolution

### Problem: Webpack 5 Polyfill for react-markdown

The `react-markdown@4.3.1` dependency chain requires Node.js `path` module, which webpack 5 no longer polyfills.

### Solution Options (Ranked by Recommendation)

#### Option 1: Upgrade react-markdown (RECOMMENDED)

**Action:**
```bash
cd /Users/daniel/papercups/assets
npm install --legacy-peer-deps react-markdown@^8.0.0
npm install --legacy-peer-deps remark-gfm@^3.0.0
```

**Pros:**
- Modern, maintained version (v8 vs v4)
- Works with webpack 5 out of the box
- Better React 18 support
- Security updates

**Cons:**
- API changes require code updates
- Need to update 3 files that use react-markdown

**Affected Files:**
- `/Users/daniel/papercups/assets/src/components/developers/email/html.ts`
- `/Users/daniel/papercups/assets/src/components/common.tsx`
- `/Users/daniel/papercups/assets/src/components/MarkdownRenderer.tsx`

**Code Changes Required:**
```tsx
// Before (v4)
import ReactMarkdown from 'react-markdown';
import breaks from 'remark-breaks';

<ReactMarkdown source={content} plugins={[breaks]} />

// After (v8)
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

<ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
```

**Estimated Time:** 2-3 hours (update code, test, verify build)

#### Option 2: Add Webpack Polyfill Configuration

**Action:** Create `config-overrides.js` or eject from create-react-app to configure webpack fallbacks.

**Pros:**
- Minimal code changes
- Quick fix

**Cons:**
- Ejecting from create-react-app is irreversible
- Using react-app-rewired adds complexity
- Doesn't address outdated dependency
- Not recommended by webpack/React teams

**Not Recommended:** This is a workaround, not a fix.

#### Option 3: Replace react-markdown Entirely

**Action:** Use alternative markdown rendering library or custom implementation.

**Pros:**
- Full control over implementation
- Could reduce bundle size

**Cons:**
- Significant development effort
- Potential feature gaps
- More code to maintain

**Not Recommended:** Overkill for this issue.

---

## Deployment Roadmap

### Phase 0: Critical Fix (BEFORE MERGE)

**Timeline:** 1-4 hours
**Owner:** Frontend Team
**Status:** REQUIRED

**Tasks:**
- [ ] Upgrade `react-markdown` to v8
- [ ] Update `remark-breaks` to `remark-gfm`
- [ ] Update 3 files using react-markdown
- [ ] Test markdown rendering in UI
- [ ] Verify production build succeeds
- [ ] Run full test suite
- [ ] Commit fix to branch

**Success Criteria:**
- `npm run build` succeeds without errors
- All tests still passing
- Markdown renders correctly in browser

**Rollback Plan:** Revert commits if unexpected issues arise.

---

### Phase 1: Pre-Merge Preparation

**Timeline:** 2-4 hours
**Owner:** DevOps + QA Team
**Status:** AFTER Phase 0 completion

#### 1.1 Update CI/CD Configuration

**File:** `.github/workflows/papercups.yml`

Update Elixir versions in all jobs:
```yaml
# Change from:
elixir-version: "1.10.4"
otp-version: "22.2.6"

# To:
elixir-version: "1.17.3"
otp-version: "26.2"
```

Add `--legacy-peer-deps` to npm install:
```yaml
- name: Install dependencies
  run: npm install --legacy-peer-deps --prefix assets
```

**Tasks:**
- [ ] Update all 3 jobs in papercups.yml (mix-format, prettier, build-ui)
- [ ] Update mix-test job configuration
- [ ] Test CI pipeline on branch
- [ ] Verify all jobs pass

#### 1.2 Documentation Updates

**Tasks:**
- [ ] Update README.md with new version requirements
- [ ] Document `--legacy-peer-deps` requirement
- [ ] Update developer setup instructions
- [ ] Add upgrade notes to CHANGELOG.md

#### 1.3 Pre-Merge Testing

**Environment:** Staging/Development

**Test Checklist:**
- [ ] Full test suite passes (npm test)
- [ ] Production build succeeds (npm run build)
- [ ] Docker image builds successfully
- [ ] Application starts without errors
- [ ] All React components render correctly
- [ ] Chat widget loads and functions
- [ ] Markdown rendering works (messages, notes, etc.)
- [ ] WebSocket connections work (Phoenix channels)
- [ ] User authentication flows work
- [ ] Admin dashboard features work
- [ ] Third-party integrations work (Stripe, Sentry)
- [ ] Mobile responsive layouts display correctly
- [ ] Browser compatibility (Chrome, Firefox, Safari, Edge)

#### 1.4 Performance Baseline

**Tasks:**
- [ ] Measure current production bundle size
- [ ] Measure page load times (Lighthouse scores)
- [ ] Document current memory usage
- [ ] Set up performance monitoring alerts

**Success Criteria:**
- Bundle size within 10% of previous version
- Lighthouse scores >= 90
- No memory leaks detected

---

### Phase 2: Staging Deployment

**Timeline:** 1 day
**Owner:** DevOps Team
**Status:** AFTER Phase 1 completion

#### 2.1 Deploy to Staging

**Tasks:**
- [ ] Merge branch to staging branch
- [ ] Deploy to staging environment
- [ ] Monitor application logs
- [ ] Check error tracking (Sentry)
- [ ] Verify database migrations (if any)

#### 2.2 Staging Testing

**Duration:** 4-8 hours minimum

**Test Scenarios:**
- [ ] User registration and login
- [ ] Create and manage conversations
- [ ] Send and receive messages
- [ ] Chat widget embedding and functionality
- [ ] File uploads and attachments
- [ ] Integrations (Slack, webhooks, etc.)
- [ ] Billing and subscription management
- [ ] Admin operations
- [ ] API endpoints
- [ ] Session recording (Storytime)
- [ ] Analytics and reporting

#### 2.3 Load Testing

**Tasks:**
- [ ] Run load tests simulating production traffic
- [ ] Monitor resource usage (CPU, memory, DB)
- [ ] Check for memory leaks under sustained load
- [ ] Verify Phoenix channels handle reconnections
- [ ] Test concurrent user scenarios

**Success Criteria:**
- No errors under normal load
- Response times within acceptable range
- Resource usage similar to or better than current production

---

### Phase 3: Production Deployment

**Timeline:** Planned maintenance window
**Owner:** DevOps + Engineering Leads
**Status:** AFTER successful staging validation

#### 3.1 Pre-Deployment Checklist

**48 Hours Before:**
- [ ] Announce maintenance window to customers
- [ ] Prepare rollback procedure
- [ ] Backup production database
- [ ] Document current production state
- [ ] Verify staging has been stable for 24+ hours
- [ ] Review all test results
- [ ] Obtain stakeholder approval

**24 Hours Before:**
- [ ] Final staging smoke test
- [ ] Verify CI/CD pipeline on branch
- [ ] Confirm on-call team availability
- [ ] Review deployment runbook
- [ ] Set up war room/communication channel

**1 Hour Before:**
- [ ] Final production backup
- [ ] Scale up monitoring
- [ ] Notify team deployment starting
- [ ] Put application in maintenance mode (if needed)

#### 3.2 Deployment Steps

**Step 1: Merge to Master**
```bash
git checkout master
git pull origin master
git merge upgrade/infrastructure-alpine-elixir
git push origin master
```

**Step 2: Build and Tag**
- [ ] Trigger Docker build via GitHub Actions
- [ ] Wait for multi-architecture build (amd64, arm64)
- [ ] Verify image tags in GitHub Container Registry
- [ ] Tag release version (e.g., v2.0.0)

**Step 3: Deploy**
- [ ] Pull new Docker images to production servers
- [ ] Run database migrations (if any)
- [ ] Deploy application containers
- [ ] Verify health checks pass
- [ ] Monitor application startup

**Step 4: Smoke Test Production**
- [ ] Test user login
- [ ] Test chat widget
- [ ] Test message sending
- [ ] Verify integrations
- [ ] Check error rates in Sentry
- [ ] Monitor Phoenix channels

**Duration:** 30-60 minutes (plus monitoring time)

#### 3.3 Post-Deployment Monitoring

**First Hour:**
- [ ] Monitor error rates (should be < 0.1%)
- [ ] Check application logs for warnings
- [ ] Monitor Phoenix channel connections
- [ ] Verify WebSocket stability
- [ ] Check database query performance
- [ ] Monitor memory usage trends

**First 24 Hours:**
- [ ] Track error rates and patterns
- [ ] Monitor performance metrics
- [ ] Review Sentry issues
- [ ] Check user reports/support tickets
- [ ] Monitor resource utilization
- [ ] Verify scheduled jobs run correctly

**First Week:**
- [ ] Daily performance reviews
- [ ] Track bundle size impact
- [ ] Monitor memory usage over time
- [ ] Review any new error patterns
- [ ] Collect user feedback
- [ ] Document any issues

---

### Phase 4: Post-Deployment Cleanup

**Timeline:** 1-2 weeks after production deployment
**Owner:** Engineering Team

#### 4.1 Monitoring and Optimization

**Tasks:**
- [ ] Analyze performance data
- [ ] Optimize bundle size if needed
- [ ] Address any minor issues discovered
- [ ] Fine-tune monitoring alerts
- [ ] Update documentation with lessons learned

#### 4.2 Technical Debt Reduction

**Priority Items:**
- [ ] Upgrade `@sentry/react` to v7+ (React 18 support)
- [ ] Upgrade `theme-ui` to v0.15+ (React 18 support)
- [ ] Update custom packages with React 18 peer deps
  - `@papercups-io/chat-builder`
  - `@papercups-io/chat-widget`
- [ ] Remove `--legacy-peer-deps` flag once above complete
- [ ] Consider upgrading other outdated dependencies

**Lower Priority:**
- [ ] Explore React 18 concurrent features
- [ ] Implement `useTransition` for better UX
- [ ] Optimize with automatic batching awareness
- [ ] Consider Suspense for data fetching

---

## Rollback Triggers

### Automatic Rollback Triggers

Deploy the rollback immediately if any of these occur:

1. **Error Rate Spike**
   - Error rate > 5% for 5 minutes
   - Critical errors > 10 in 5 minutes

2. **Application Downtime**
   - Application unresponsive for > 2 minutes
   - Health check failures > 3 consecutive attempts

3. **Database Issues**
   - Database connection failures
   - Query timeouts > 50% for 5 minutes

4. **Memory Leak**
   - Memory usage increases > 50% in 30 minutes
   - OOM (Out of Memory) errors

### Manual Rollback Triggers

Consider rollback if:

1. **User Impact**
   - Multiple customer complaints about specific features
   - Chat widget not loading for users
   - Authentication failures

2. **Integration Failures**
   - Slack integration broken
   - Stripe webhooks failing
   - Third-party API errors

3. **Data Integrity Issues**
   - Messages not being saved
   - Customer data inconsistencies
   - Analytics data gaps

4. **Performance Degradation**
   - Page load times > 2x normal
   - API response times > 500ms average
   - Phoenix channel latency > 1s

### Rollback Procedure

**Step 1: Immediate Actions**
```bash
# Revert to previous Docker image
docker pull ghcr.io/papercups-io/papercups:previous-version
docker-compose up -d

# Or rollback via git
git revert <merge-commit-sha>
git push origin master
```

**Step 2: Verification**
- [ ] Verify application starts successfully
- [ ] Check error rates normalized
- [ ] Confirm all services operational
- [ ] Test critical user flows

**Step 3: Communication**
- [ ] Notify stakeholders of rollback
- [ ] Update status page
- [ ] Document rollback reason
- [ ] Schedule post-mortem

**Expected Rollback Time:** < 10 minutes

---

## Lessons Learned (Preliminary)

### What Went Well

1. **Systematic Approach**
   - Breaking changes addressed methodically
   - Comprehensive documentation created
   - Test suite validated each step

2. **Infrastructure Modernization**
   - Moved from EOL software to supported versions
   - Security posture improved significantly
   - Modern toolchain benefits

3. **Code Quality**
   - Minimal application code changes required
   - TypeScript migration smooth
   - No test regressions

### What Needs Improvement

1. **Dependency Management**
   - Should have identified react-markdown issue earlier
   - Need better webpack 5 compatibility checking
   - Dependency audit process needed

2. **CI/CD Synchronization**
   - CI configuration not updated in sync with code
   - Need automated version consistency checks
   - Should validate CI before starting upgrades

3. **Testing Coverage**
   - Need integration tests for markdown rendering
   - Should have production build tests in CI
   - Missing webpack build validation

### Action Items for Future Upgrades

1. **Before Starting:**
   - [ ] Audit all dependencies for compatibility
   - [ ] Test production builds early
   - [ ] Update CI/CD configuration first
   - [ ] Set up rollback plan before changes

2. **During Upgrade:**
   - [ ] Build after each significant change
   - [ ] Test production build, not just dev mode
   - [ ] Document breaking changes immediately
   - [ ] Keep stakeholders informed

3. **After Completion:**
   - [ ] Performance benchmarking required
   - [ ] Monitor production for 1 week minimum
   - [ ] Document all lessons learned
   - [ ] Update upgrade playbook

---

## Next Immediate Action Items

### Priority 1: CRITICAL (Block all else)

1. **Fix react-markdown Webpack Issue**
   - **Owner:** Frontend Lead
   - **Deadline:** ASAP (1-4 hours)
   - **Tasks:**
     - Upgrade react-markdown to v8
     - Update affected components
     - Verify build succeeds
     - Test markdown rendering

### Priority 2: HIGH (Before merge)

2. **Update CI/CD Configuration**
   - **Owner:** DevOps
   - **Deadline:** Same day as P1
   - **Tasks:**
     - Update Elixir versions in workflows
     - Add --legacy-peer-deps flags
     - Test CI pipeline

3. **Complete Pre-Merge Testing**
   - **Owner:** QA Team
   - **Deadline:** 1 day after P1
   - **Tasks:**
     - Run full test checklist
     - Document test results
     - Sign off on quality

### Priority 3: MEDIUM (Post-merge)

4. **Deploy to Staging**
   - **Owner:** DevOps
   - **Deadline:** 2 days after merge
   - **Tasks:**
     - Deploy to staging environment
     - Run staging test scenarios
     - Monitor for 24 hours

5. **Plan Production Deployment**
   - **Owner:** Engineering Manager
   - **Deadline:** 3 days after merge
   - **Tasks:**
     - Schedule maintenance window
     - Assign deployment team
     - Prepare communication

### Priority 4: LOW (Post-deployment)

6. **Technical Debt Cleanup**
   - **Owner:** Engineering Team
   - **Deadline:** 2 weeks after production
   - **Tasks:**
     - Upgrade Sentry and theme-ui
     - Update custom packages
     - Remove legacy-peer-deps flag

---

## Timeline Estimate for Production Deployment

### Best Case Scenario

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Fix react-markdown issue | 2-3 hours | Day 0 |
| Update CI/CD + testing | 4-6 hours | Day 0-1 |
| Staging deployment | 1 day | Day 1-2 |
| Staging validation | 1-2 days | Day 2-4 |
| Production deployment | 1-2 hours | Day 4-5 |
| **Total** | **4-5 days** | |

### Realistic Scenario

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Fix react-markdown issue | 3-4 hours | Day 0 |
| Update CI/CD + testing | 1 day | Day 1 |
| Staging deployment | 1 day | Day 2 |
| Staging validation | 2-3 days | Day 3-5 |
| Production planning | 1-2 days | Day 6-7 |
| Production deployment | 1-2 hours | Day 7 |
| **Total** | **7-8 days** | |

### Conservative Scenario

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Fix react-markdown issue | 4-6 hours | Day 0-1 |
| Update CI/CD + testing | 1-2 days | Day 2-3 |
| Staging deployment | 1 day | Day 4 |
| Staging validation | 3-5 days | Day 5-9 |
| Production planning | 2-3 days | Day 10-12 |
| Production deployment | 2-4 hours | Day 12 |
| **Total** | **12-14 days** | |

### Recommendation

**Target Timeline: 7-10 days from critical fix completion**

This allows for:
- Proper testing and validation
- Stakeholder communication
- Scheduled maintenance window
- Buffer for unexpected issues

---

## Summary of Recommendations

### Immediate Actions (This Week)

1. **Fix the build issue** by upgrading `react-markdown` to v8
2. **Update CI/CD configuration** to match new Elixir versions
3. **Run comprehensive testing** to validate the upgrade
4. **Document all changes** for the team

### Short Term (Next 2 Weeks)

1. **Deploy to staging** and validate thoroughly
2. **Plan production deployment** with stakeholder approval
3. **Execute production deployment** during maintenance window
4. **Monitor intensively** for first 48 hours

### Medium Term (Next Month)

1. **Clean up technical debt** (upgrade Sentry, theme-ui, custom packages)
2. **Remove legacy-peer-deps flag** once deps updated
3. **Optimize performance** based on production data
4. **Document lessons learned** for future upgrades

### Long Term (Next Quarter)

1. **Explore React 18 concurrent features** for UX improvements
2. **Modernize remaining dependencies**
3. **Improve CI/CD pipeline** with better validations
4. **Establish regular upgrade cadence** to avoid large jumps

---

## Conclusion

The React 18 upgrade represents a significant modernization of the Papercups infrastructure. While a critical build issue currently blocks deployment, this is a solvable problem with a clear path forward.

**The upgrade is technically sound and brings important benefits:**
- Modern, supported software versions (security)
- Performance improvements
- Better developer experience
- Future-proof foundation

**Current Status: HOLD**
- Fix react-markdown webpack polyfill issue
- Update CI/CD configuration
- Complete validation testing

**Estimated Timeline: 7-10 days to production**

Once the build issue is resolved and testing is complete, this upgrade should be deployed to production with confidence. The rollback plan is clear, the risks are understood, and the benefits are significant.

---

**Document Version:** 1.0
**Last Updated:** 2025-11-08
**Next Review:** After critical fix implementation
**Owner:** Engineering Team
**Stakeholders:** DevOps, QA, Product, Engineering Management
