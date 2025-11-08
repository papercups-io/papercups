# IMMEDIATE ACTIONS REQUIRED

**Date:** 2025-11-08
**Status:** 🔴 CRITICAL - BUILD BLOCKED
**Branch:** `upgrade/infrastructure-alpine-elixir`

---

## ⚠️ BLOCKER: Production Build Fails

**Error:**
```
Module not found: Error: Can't resolve 'path' in 'node_modules/vfile'
BREAKING CHANGE: webpack < 5 used to include polyfills for node.js core modules...
```

**Impact:** Cannot deploy to production until fixed.

---

## 🚨 DO THIS NOW (Priority 1)

### Fix react-markdown Dependency Issue

**Time Required:** 2-4 hours
**Owner:** Frontend Team Lead

#### Step 1: Upgrade Dependencies (5 minutes)

```bash
cd /Users/daniel/papercups/assets

# Upgrade react-markdown to v8
npm install --legacy-peer-deps react-markdown@^8.0.0

# Upgrade remark plugin
npm install --legacy-peer-deps remark-gfm@^3.0.0

# Remove old plugin (if installed)
npm uninstall remark-breaks
```

#### Step 2: Update 3 Files (1-2 hours)

**File 1:** `/Users/daniel/papercups/assets/src/components/MarkdownRenderer.tsx`

```tsx
// BEFORE (v4 API)
import ReactMarkdown from 'react-markdown';
import breaks from 'remark-breaks';

<ReactMarkdown
  source={content}
  plugins={[breaks]}
/>

// AFTER (v8 API)
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

<ReactMarkdown remarkPlugins={[remarkGfm]}>
  {content}
</ReactMarkdown>
```

**File 2:** `/Users/daniel/papercups/assets/src/components/common.tsx`

Find all `ReactMarkdown` usages and update to v8 API:
- Change `source` prop to children
- Change `plugins` prop to `remarkPlugins`
- Replace `remark-breaks` with `remark-gfm`

**File 3:** `/Users/daniel/papercups/assets/src/components/developers/email/html.ts`

Update any markdown rendering to use v8 API.

#### Step 3: Test Build (15 minutes)

```bash
cd /Users/daniel/papercups/assets

# This MUST succeed
npm run build

# Expected output: "Compiled successfully!"
# If it fails, review errors and fix
```

#### Step 4: Run Tests (10 minutes)

```bash
cd /Users/daniel/papercups/assets

# All tests must pass
npm test -- --watchAll=false

# Expected: "Tests: 32 passed, 32 total"
```

#### Step 5: Manual Testing (30-60 minutes)

Start dev server:
```bash
npm start
```

Test markdown rendering in:
- [ ] Chat messages (customer to agent)
- [ ] Chat messages (agent to customer)
- [ ] Customer notes
- [ ] Email templates
- [ ] Any other places markdown is used

**Look for:**
- Text renders correctly
- Line breaks work
- Lists work (ordered and unordered)
- Links work
- Code blocks work
- No console errors

#### Step 6: Commit Fix (5 minutes)

```bash
git add .
git commit -m "Fix webpack 5 polyfill issue by upgrading react-markdown to v8

- Upgrade react-markdown from v4.3.1 to v8.0.0
- Replace remark-breaks with remark-gfm v3.0.0
- Update API usage: source prop -> children, plugins -> remarkPlugins
- Fixes webpack 5 build error for 'path' polyfill in vfile package

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push origin upgrade/infrastructure-alpine-elixir
```

**SUCCESS CRITERIA:**
- ✅ `npm run build` succeeds without errors
- ✅ All tests pass (32/32)
- ✅ Markdown renders correctly in browser
- ✅ No console errors

---

## 📋 NEXT STEPS (Priority 2)

### After Build Fix is Complete

#### 1. Update CI/CD Configuration (2 hours)

**File:** `.github/workflows/papercups.yml`

Update all jobs to use Elixir 1.17.3:

```yaml
# In all jobs, change from:
elixir-version: "1.10.4" or "1.11.4"
otp-version: "22.2.6" or "23.0.3"

# To:
elixir-version: "1.17.3"
otp-version: "26.2"
```

Add `--legacy-peer-deps` to npm install commands:

```yaml
# Change from:
run: npm install --prefix assets

# To:
run: npm install --legacy-peer-deps --prefix assets
```

**Test CI Pipeline:**
```bash
git push origin upgrade/infrastructure-alpine-elixir
# Watch GitHub Actions to ensure all jobs pass
```

#### 2. Complete Full Testing (4-8 hours)

**Testing Checklist:** See `/Users/daniel/papercups/DEPLOYMENT_CHECKLIST.md` Phase 1.4

Quick version:
- [ ] All automated tests pass
- [ ] Manual testing of all features
- [ ] Browser compatibility (Chrome, Firefox, Safari, Edge)
- [ ] Mobile testing (iOS Safari, Android Chrome)
- [ ] Performance baseline (Lighthouse scores)

#### 3. Code Review and Approval (1-2 hours)

- [ ] Create PR: `upgrade/infrastructure-alpine-elixir` → `master`
- [ ] Tag reviewers (minimum 2)
- [ ] Address review comments
- [ ] Obtain approvals
- [ ] Ensure CI/CD passes

---

## 📊 THEN DEPLOY (Priority 3)

### Staging Deployment (1-2 days)

1. **Deploy to Staging**
   - Deploy branch to staging environment
   - Run full test suite on staging
   - Monitor for 24+ hours

2. **Validate Stability**
   - No errors in logs
   - Performance acceptable
   - All features working
   - Load testing passes

### Production Deployment (7-10 days total)

**See:** `/Users/daniel/papercups/DEPLOYMENT_ROADMAP.md` for complete plan

**Timeline:**
- Day 0: Fix build issue (TODAY)
- Day 1: Update CI/CD + testing
- Day 2-5: Staging deployment + validation
- Day 7-10: Production deployment

**Prerequisites:**
- ✅ Build fix complete
- ✅ All tests passing
- ✅ CI/CD updated and passing
- ✅ Staging stable for 24+ hours
- ✅ Stakeholder approval

---

## 🚑 ROLLBACK PLAN

If anything goes wrong, rollback is quick:

```bash
# Option 1: Revert Docker image
docker pull ghcr.io/papercups-io/papercups:<previous-version>
docker-compose up -d

# Option 2: Revert git commit
git revert <merge-commit-sha>
git push origin master
```

**Rollback Time:** < 10 minutes

---

## 📚 DOCUMENTATION

All documentation is complete and ready:

1. **IMMEDIATE_ACTIONS.md** (this file)
   - Quick reference for immediate next steps

2. **EXECUTIVE_SUMMARY.md** (9.9 KB)
   - High-level overview for stakeholders
   - Go/no-go recommendation
   - Risk assessment

3. **DEPLOYMENT_ROADMAP.md** (23 KB)
   - Complete deployment strategy
   - Risk analysis
   - Timeline estimates
   - Success metrics

4. **DEPLOYMENT_CHECKLIST.md** (19 KB)
   - Detailed step-by-step checklist
   - All phases of deployment
   - Sign-off sheet

5. **UPGRADE_NOTES.md** (13 KB)
   - Technical changelog
   - All commits documented
   - Breaking changes listed

**Location:** `/Users/daniel/papercups/`

---

## 👥 TEAM ASSIGNMENTS

### Immediate (Today)

**Frontend Lead:**
- [ ] Fix react-markdown issue
- [ ] Test build and functionality
- [ ] Commit fix to branch

**DevOps Lead:**
- [ ] Update CI/CD configuration
- [ ] Test pipeline passes
- [ ] Prepare staging environment

**QA Lead:**
- [ ] Review test checklist
- [ ] Prepare test scenarios
- [ ] Ready to start testing after build fix

### This Week

**Engineering Manager:**
- [ ] Review documentation
- [ ] Coordinate team efforts
- [ ] Stakeholder communication

**Product Manager:**
- [ ] Review customer communication
- [ ] Approve deployment timeline
- [ ] Prepare announcements

---

## ⏱️ TIME ESTIMATES

| Task | Time | When |
|------|------|------|
| Fix react-markdown | 2-4 hours | TODAY |
| Update CI/CD | 2 hours | TODAY |
| Full testing | 4-8 hours | DAY 1 |
| Code review | 1-2 hours | DAY 1 |
| Staging deploy | 2 hours | DAY 2 |
| Staging validation | 2-3 days | DAY 2-5 |
| Production prep | 1-2 days | DAY 6-7 |
| Production deploy | 1-2 hours | DAY 7-10 |
| **TOTAL** | **7-10 days** | |

---

## ✅ SUCCESS METRICS

### Must Have (Before Production)
- ✅ Production build succeeds
- ✅ All 32 tests pass
- ✅ CI/CD pipeline passes
- ✅ Staging stable 24+ hours
- ✅ All manual tests pass
- ✅ Stakeholder approval

### Should Have
- ✅ Zero rollbacks required
- ✅ Error rate < 0.5%
- ✅ Performance within 10% of baseline
- ✅ No critical bugs found

### Nice to Have
- ✅ Performance improvements observed
- ✅ Bundle size reduced
- ✅ Positive user feedback
- ✅ No support tickets related to upgrade

---

## 🎯 CURRENT STATUS

**What's Done:**
- ✅ React 18.2.0 upgraded
- ✅ Elixir 1.17.3 upgraded
- ✅ Alpine 3.21 upgraded
- ✅ TypeScript 4.9 upgraded
- ✅ All tests passing (32/32)
- ✅ createRoot API implemented
- ✅ Complete documentation created

**What's Blocking:**
- ❌ Production build fails (webpack polyfill)

**What's Next:**
1. Fix react-markdown (2-4 hours)
2. Update CI/CD (2 hours)
3. Full testing (4-8 hours)
4. Deploy to staging (1-2 days)
5. Deploy to production (7-10 days total)

---

## 💡 QUICK TIPS

### For Frontend Dev Fixing react-markdown

**Common Issues:**
- Make sure to update ALL files using ReactMarkdown
- The API changed significantly between v4 and v8
- Test markdown rendering visually, not just build
- Check browser console for runtime errors

**API Changes:**
```tsx
// v4 → v8 changes:
source → children (as prop value)
plugins → remarkPlugins
renderers → components
escapeHtml → removed (XSS protection built-in)
```

### For DevOps Updating CI/CD

**Don't forget:**
- Update ALL jobs in the workflow
- Both Elixir version AND OTP version
- Add --legacy-peer-deps to ALL npm install commands
- Test the pipeline after pushing

### For QA Testing

**Focus on:**
- Markdown rendering (most likely to have issues from fix)
- Chat widget (uses React heavily)
- Real-time features (WebSocket/Phoenix channels)
- Browser compatibility (especially Safari)

---

## 📞 NEED HELP?

**Questions?**
- Check the detailed docs in `/Users/daniel/papercups/`
- Review React Markdown v8 migration guide: https://github.com/remarkjs/react-markdown
- Check webpack 5 migration guide: https://webpack.js.org/migrate/5/

**Stuck?**
- Ask in #engineering Slack channel
- Tag @frontend-team for react-markdown issues
- Tag @devops-team for CI/CD issues
- Tag @qa-team for testing questions

**Emergency?**
- Contact Engineering Manager
- Escalate to CTO if needed
- Don't hesitate to ask for help!

---

## 🎉 AFTER COMPLETION

Once deployed successfully:

1. **Celebrate!** This is a significant upgrade
2. **Document lessons learned**
3. **Plan technical debt cleanup** (upgrade Sentry, theme-ui)
4. **Explore React 18 features** (useTransition, Suspense)
5. **Schedule next upgrade** (don't wait too long!)

---

**START HERE:** Step 1 - Fix react-markdown
**ESTIMATED TIME:** 2-4 hours
**PRIORITY:** 🔴 CRITICAL

**Good luck! You've got this! 💪**
