# React 18 Upgrade: Deployment Checklist

**Branch:** `upgrade/infrastructure-alpine-elixir`
**Last Updated:** 2025-11-08

---

## Phase 0: Critical Fix (REQUIRED BEFORE MERGE)

**Status:** 🔴 BLOCKED
**Owner:** Frontend Team
**Estimated Time:** 2-4 hours

### Fix react-markdown Webpack Issue

- [ ] **Upgrade react-markdown**
  ```bash
  cd /Users/daniel/papercups/assets
  npm install --legacy-peer-deps react-markdown@^8.0.0
  npm install --legacy-peer-deps remark-gfm@^3.0.0
  ```

- [ ] **Update MarkdownRenderer.tsx**
  - File: `/Users/daniel/papercups/assets/src/components/MarkdownRenderer.tsx`
  - Change: Update to v8 API (`remarkPlugins` prop, children prop)

- [ ] **Update common.tsx**
  - File: `/Users/daniel/papercups/assets/src/components/common.tsx`
  - Change: Update react-markdown usage

- [ ] **Update email/html.ts**
  - File: `/Users/daniel/papercups/assets/src/components/developers/email/html.ts`
  - Change: Update react-markdown usage

- [ ] **Verify Build**
  ```bash
  cd /Users/daniel/papercups/assets
  npm run build
  ```
  Expected: Build succeeds without errors

- [ ] **Run Tests**
  ```bash
  cd /Users/daniel/papercups/assets
  npm test -- --watchAll=false
  ```
  Expected: All tests pass

- [ ] **Test Markdown Rendering**
  - Start dev server: `npm start`
  - Test markdown in chat messages
  - Test markdown in customer notes
  - Test markdown in any other locations

- [ ] **Commit Fix**
  ```bash
  git add .
  git commit -m "Fix webpack 5 polyfill issue by upgrading react-markdown to v8"
  git push origin upgrade/infrastructure-alpine-elixir
  ```

**Success Criteria:**
- ✅ Production build succeeds
- ✅ All tests passing (32/32)
- ✅ Markdown renders correctly in browser

---

## Phase 1: Pre-Merge Preparation

**Status:** ⏸️ Waiting on Phase 0
**Owner:** DevOps + QA Team
**Estimated Time:** 4-8 hours

### 1.1 Update CI/CD Configuration

- [ ] **Update papercups.yml**
  - File: `.github/workflows/papercups.yml`

- [ ] **Update mix-format job**
  ```yaml
  elixir-version: "1.17.3"
  otp-version: "26.2"
  ```

- [ ] **Update prettier job**
  ```yaml
  elixir-version: "1.17.3"
  otp-version: "26.2"
  ```
  Add `--legacy-peer-deps`:
  ```yaml
  run: npm install --legacy-peer-deps --prefix assets
  ```

- [ ] **Update build-ui job**
  ```yaml
  elixir-version: "1.17.3"
  otp-version: "26.2"
  ```
  Add `--legacy-peer-deps`:
  ```yaml
  run: npm install --legacy-peer-deps --prefix assets
  ```

- [ ] **Update mix-test job**
  ```yaml
  elixir-version: "1.17.3"
  otp-version: "26.2"
  ```

- [ ] **Test CI Pipeline**
  - Push changes to branch
  - Verify all GitHub Actions pass
  - Check build logs for errors

### 1.2 Documentation Updates

- [ ] **Update README.md**
  - Add React 18 to tech stack
  - Update Node.js version requirement
  - Document `--legacy-peer-deps` requirement

- [ ] **Update CHANGELOG.md**
  - Add entry for React 18 upgrade
  - List all version changes
  - Note breaking changes

- [ ] **Developer Setup Docs**
  - Update local setup instructions
  - Document new npm install command
  - Add troubleshooting section

### 1.3 Code Review

- [ ] **Request Code Review**
  - Create PR from branch to master
  - Tag reviewers
  - Link to upgrade documentation

- [ ] **Review Checklist**
  - All commits follow convention
  - No debug code or console.logs
  - TypeScript types correct
  - Tests cover changes
  - Documentation updated

- [ ] **Approval**
  - Minimum 2 approvals
  - All comments addressed
  - CI/CD passing

### 1.4 Pre-Merge Testing

#### Build Tests
- [ ] Production build succeeds
  ```bash
  cd /Users/daniel/papercups/assets
  npm run build
  ```

- [ ] Docker image builds
  ```bash
  cd /Users/daniel/papercups
  docker build -t papercups-test .
  ```

- [ ] Docker image runs
  ```bash
  docker run -p 4000:4000 papercups-test
  ```

#### Automated Tests
- [ ] All unit tests pass
  ```bash
  npm test -- --watchAll=false
  ```

- [ ] All integration tests pass (if any)

- [ ] Elixir tests pass
  ```bash
  mix test
  ```

#### Manual Testing
- [ ] **Authentication**
  - [ ] User registration
  - [ ] User login
  - [ ] Password reset
  - [ ] Logout

- [ ] **Core Features**
  - [ ] Create conversation
  - [ ] Send message
  - [ ] Receive message
  - [ ] Upload file/attachment
  - [ ] Markdown rendering in messages
  - [ ] Emoji rendering
  - [ ] Delete message
  - [ ] Close conversation

- [ ] **Chat Widget**
  - [ ] Widget loads on page
  - [ ] Widget opens/closes
  - [ ] Send message from widget
  - [ ] Receive message in widget
  - [ ] File upload from widget
  - [ ] Widget customization

- [ ] **Admin Features**
  - [ ] View dashboard
  - [ ] User management
  - [ ] Team settings
  - [ ] Integrations page
  - [ ] Billing/subscription
  - [ ] API keys

- [ ] **Integrations**
  - [ ] Slack integration works
  - [ ] Webhooks deliver
  - [ ] Email forwarding
  - [ ] Stripe webhooks

- [ ] **Session Recording (Storytime)**
  - [ ] Recording starts
  - [ ] Playback works
  - [ ] Events captured

#### Browser Testing
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari (iOS)
- [ ] Mobile Chrome (Android)

#### Performance Testing
- [ ] **Bundle Size Check**
  ```bash
  cd /Users/daniel/papercups/assets/build/static/js
  ls -lh *.js
  ```
  Record main bundle size: _________ KB

- [ ] **Lighthouse Scores**
  - Performance: _____
  - Accessibility: _____
  - Best Practices: _____
  - SEO: _____

- [ ] **Memory Usage**
  - Open DevTools → Performance Monitor
  - Use app for 5 minutes
  - Check for memory leaks
  - Memory stays stable: ☐

**Success Criteria:**
- ✅ All tests passing
- ✅ All manual tests pass
- ✅ All browsers work
- ✅ Performance acceptable
- ✅ Code review approved

---

## Phase 2: Staging Deployment

**Status:** ⏸️ Waiting on Phase 1
**Owner:** DevOps Team
**Estimated Time:** 1 day

### 2.1 Pre-Staging Checklist

- [ ] Phase 0 complete (build fix)
- [ ] Phase 1 complete (testing)
- [ ] Code review approved
- [ ] CI/CD passing
- [ ] Stakeholder approval obtained

### 2.2 Deploy to Staging

- [ ] **Backup Staging Database**
  ```bash
  pg_dump staging_db > staging_backup_$(date +%Y%m%d).sql
  ```

- [ ] **Deploy Branch to Staging**
  ```bash
  git checkout upgrade/infrastructure-alpine-elixir
  git pull origin upgrade/infrastructure-alpine-elixir
  # Deploy to staging (method depends on infrastructure)
  ```

- [ ] **Verify Deployment**
  - [ ] Application starts successfully
  - [ ] Health check passes
  - [ ] No errors in logs (first 5 minutes)

### 2.3 Staging Smoke Test (Immediate)

- [ ] Home page loads
- [ ] Login works
- [ ] Dashboard loads
- [ ] Chat widget loads
- [ ] WebSocket connects
- [ ] No console errors

### 2.4 Staging Full Test (4-8 hours)

#### User Flows
- [ ] Complete user registration flow
- [ ] Complete password reset flow
- [ ] Complete conversation lifecycle
- [ ] Complete file upload flow
- [ ] Complete integration setup

#### Data Operations
- [ ] Create new customer
- [ ] Update customer info
- [ ] Delete customer
- [ ] Create conversation
- [ ] Archive conversation
- [ ] Export data

#### Integrations
- [ ] Test Slack integration
- [ ] Test webhook delivery
- [ ] Test email forwarding
- [ ] Test Stripe checkout (test mode)
- [ ] Test API endpoints

#### Performance
- [ ] Page load times < 2s
- [ ] API responses < 500ms
- [ ] WebSocket latency < 100ms
- [ ] No memory leaks after 30min

### 2.5 Staging Load Test

- [ ] **Run Load Test**
  - Simulate 50 concurrent users
  - Duration: 30 minutes
  - Monitor resource usage

- [ ] **Check Results**
  - [ ] No errors under load
  - [ ] Response times acceptable
  - [ ] Memory usage stable
  - [ ] CPU usage < 80%
  - [ ] Database connections stable

### 2.6 Staging Monitoring (24+ hours)

- [ ] **Monitor Error Rates**
  - [ ] Check Sentry for new errors
  - [ ] Review application logs
  - [ ] Check database logs

- [ ] **Monitor Performance**
  - [ ] Track response times
  - [ ] Monitor memory usage
  - [ ] Check WebSocket connections
  - [ ] Verify background jobs run

- [ ] **Stability Check**
  - [ ] No crashes or restarts
  - [ ] No memory leaks
  - [ ] No performance degradation
  - [ ] No data integrity issues

**Success Criteria:**
- ✅ Staging stable for 24+ hours
- ✅ All tests passing
- ✅ No critical errors
- ✅ Performance acceptable

---

## Phase 3: Production Deployment

**Status:** ⏸️ Waiting on Phase 2
**Owner:** DevOps + Engineering Leads
**Estimated Time:** 2-4 hours (plus monitoring)

### 3.1 Pre-Deployment (48 Hours Before)

- [ ] **Customer Communication**
  - [ ] Draft maintenance announcement
  - [ ] Send email to customers
  - [ ] Update status page
  - [ ] Post in customer Slack channels

- [ ] **Internal Preparation**
  - [ ] Schedule deployment time
  - [ ] Assign deployment team
  - [ ] Assign on-call engineer
  - [ ] Review rollback procedure
  - [ ] Set up war room/Slack channel

- [ ] **Technical Preparation**
  - [ ] Review deployment runbook
  - [ ] Test rollback procedure on staging
  - [ ] Backup production database
  - [ ] Document current production state

- [ ] **Stakeholder Approval**
  - [ ] Engineering Manager approval
  - [ ] CTO approval
  - [ ] Product approval (if needed)

### 3.2 Pre-Deployment (24 Hours Before)

- [ ] **Final Staging Check**
  - [ ] Staging still stable
  - [ ] No new issues discovered
  - [ ] Performance still good

- [ ] **Team Readiness**
  - [ ] Deployment team confirmed
  - [ ] On-call confirmed available
  - [ ] Communication plan confirmed

- [ ] **Final Preparations**
  - [ ] Review deployment checklist
  - [ ] Verify monitoring in place
  - [ ] Test alerting works
  - [ ] Prepare rollback plan

### 3.3 Pre-Deployment (1 Hour Before)

- [ ] **Final Checks**
  - [ ] Production health check
  - [ ] Current error rates normal
  - [ ] No ongoing incidents
  - [ ] Team ready in war room

- [ ] **Final Backup**
  ```bash
  pg_dump production_db > production_backup_$(date +%Y%m%d_%H%M%S).sql
  ```

- [ ] **Prepare Monitoring**
  - [ ] Open Sentry dashboard
  - [ ] Open application logs
  - [ ] Open metrics dashboard
  - [ ] Set up alerting

- [ ] **Notify Team**
  - [ ] Post in #engineering
  - [ ] Update status page to "maintenance"
  - [ ] Deployment starting in 5 minutes

### 3.4 Deployment (Execute)

- [ ] **Merge to Master**
  ```bash
  git checkout master
  git pull origin master
  git merge upgrade/infrastructure-alpine-elixir
  git push origin master
  ```

- [ ] **Tag Release**
  ```bash
  git tag -a v2.0.0 -m "React 18 upgrade and infrastructure modernization"
  git push origin v2.0.0
  ```

- [ ] **Build Docker Image**
  - [ ] Trigger GitHub Actions build
  - [ ] Wait for build completion
  - [ ] Verify multi-arch build (amd64, arm64)
  - [ ] Check image tags in registry

- [ ] **Deploy to Production**
  ```bash
  # Pull new images
  docker pull ghcr.io/papercups-io/papercups:latest

  # Deploy (method depends on infrastructure)
  docker-compose up -d
  # OR kubectl rollout restart deployment/papercups
  # OR your deployment method
  ```

- [ ] **Verify Deployment**
  - [ ] Health check passes
  - [ ] Application starts successfully
  - [ ] No immediate errors in logs

### 3.5 Post-Deployment Smoke Test (Immediate)

- [ ] **Critical Paths** (5-10 minutes)
  - [ ] Home page loads
  - [ ] User can login
  - [ ] Dashboard loads
  - [ ] Chat widget loads
  - [ ] Can send/receive message
  - [ ] WebSocket connections work
  - [ ] No console errors

- [ ] **Error Monitoring**
  - [ ] Check Sentry for new errors
  - [ ] Review application logs
  - [ ] Check error rates dashboard

- [ ] **Quick Performance Check**
  - [ ] Page load times normal
  - [ ] API response times normal
  - [ ] No memory spikes

**Rollback Decision Point:**
- If smoke test fails → Execute rollback immediately
- If smoke test passes → Continue to monitoring phase

### 3.6 Post-Deployment Monitoring (First Hour)

- [ ] **Every 5 Minutes: Check Metrics**
  - [ ] Error rate < 0.1%
  - [ ] Response times < 500ms avg
  - [ ] Memory usage stable
  - [ ] CPU usage normal
  - [ ] WebSocket connections stable

- [ ] **Every 15 Minutes: Review Logs**
  - [ ] Application logs
  - [ ] Database logs
  - [ ] Phoenix channel logs
  - [ ] Background job logs

- [ ] **Every 30 Minutes: Test Features**
  - [ ] User flows work
  - [ ] Integrations work
  - [ ] No user complaints

- [ ] **Continuous Monitoring**
  - [ ] Watch Sentry for errors
  - [ ] Monitor support channels
  - [ ] Track metrics dashboards

**Rollback Decision Point:**
- If error rate > 1% → Consider rollback
- If critical feature broken → Execute rollback
- If no issues → Continue to extended monitoring

### 3.7 Post-Deployment Monitoring (First 24 Hours)

- [ ] **Every Hour: Metrics Review**
  - [ ] Error rates trending
  - [ ] Performance metrics
  - [ ] Resource utilization
  - [ ] User activity normal

- [ ] **Every 4 Hours: Deep Check**
  - [ ] Test critical user flows
  - [ ] Review Sentry issues
  - [ ] Check support tickets
  - [ ] Verify integrations

- [ ] **Daily Summary** (End of Day 1)
  - [ ] Document any issues
  - [ ] Performance vs baseline
  - [ ] Error rate summary
  - [ ] User feedback summary

### 3.8 Post-Deployment Monitoring (First Week)

- [ ] **Daily Reviews**
  - [ ] Performance metrics trending
  - [ ] Error patterns analysis
  - [ ] Support ticket review
  - [ ] User feedback collection

- [ ] **Mid-Week Check** (Day 3-4)
  - [ ] Performance vs baseline
  - [ ] Any degradation?
  - [ ] Any new error patterns?
  - [ ] User satisfaction

- [ ] **End of Week Review**
  - [ ] Deployment success metrics
  - [ ] Performance summary
  - [ ] Issues encountered
  - [ ] Lessons learned

**Success Criteria:**
- ✅ Error rate < 0.5% average
- ✅ No critical issues
- ✅ Performance acceptable
- ✅ No rollbacks required
- ✅ Positive user feedback

### 3.9 Communication

- [ ] **Immediate (After Smoke Test)**
  - [ ] Update status page to "operational"
  - [ ] Post in #engineering: "Deployment complete"
  - [ ] Notify stakeholders

- [ ] **4 Hours After**
  - [ ] Post update in #engineering
  - [ ] Share metrics summary
  - [ ] Highlight any issues

- [ ] **24 Hours After**
  - [ ] Send deployment summary to stakeholders
  - [ ] Post customer announcement
  - [ ] Update changelog/release notes

- [ ] **1 Week After**
  - [ ] Post-deployment report
  - [ ] Lessons learned doc
  - [ ] Celebrate success! 🎉

---

## Phase 4: Post-Deployment Cleanup

**Status:** ⏸️ Waiting on Phase 3
**Owner:** Engineering Team
**Timeline:** 1-2 weeks after production

### 4.1 Performance Optimization

- [ ] **Analyze Production Metrics**
  - [ ] Compare bundle size to baseline
  - [ ] Analyze page load times
  - [ ] Check memory usage patterns
  - [ ] Review error patterns

- [ ] **Optimize if Needed**
  - [ ] Code splitting improvements
  - [ ] Bundle size reduction
  - [ ] Performance tuning
  - [ ] Caching optimizations

### 4.2 Technical Debt Reduction

#### High Priority
- [ ] **Upgrade @sentry/react**
  ```bash
  npm install --legacy-peer-deps @sentry/react@^7.0.0
  ```
  - Test error tracking
  - Update Sentry configuration
  - Verify integrations

- [ ] **Upgrade theme-ui**
  ```bash
  npm install --legacy-peer-deps theme-ui@^0.15.0
  ```
  - Test UI components
  - Update theme configuration
  - Verify styling

#### Medium Priority
- [ ] **Update @papercups-io/chat-builder**
  - Update peer dependencies to React 18
  - Publish new version
  - Update in main app

- [ ] **Update @papercups-io/chat-widget**
  - Update peer dependencies to React 18
  - Publish new version
  - Update in main app

#### Low Priority
- [ ] **Remove --legacy-peer-deps**
  - After all packages updated
  - Test npm install without flag
  - Update documentation

### 4.3 Documentation

- [ ] **Update Main Documentation**
  - [ ] README.md final updates
  - [ ] CHANGELOG.md complete
  - [ ] API docs (if needed)

- [ ] **Create Post-Mortem**
  - [ ] What went well
  - [ ] What went wrong
  - [ ] Lessons learned
  - [ ] Action items

- [ ] **Update Runbooks**
  - [ ] Deployment procedure
  - [ ] Rollback procedure
  - [ ] Troubleshooting guide

### 4.4 Future Planning

- [ ] **Explore React 18 Features**
  - [ ] Identify use cases for useTransition
  - [ ] Consider Suspense for data fetching
  - [ ] Plan concurrent features adoption

- [ ] **Dependency Modernization**
  - [ ] Audit remaining old dependencies
  - [ ] Plan next upgrade cycle
  - [ ] Schedule regular dependency updates

---

## Rollback Procedure

### When to Rollback

**Automatic Triggers:**
- Error rate > 5% for 5 minutes
- Application downtime > 2 minutes
- Memory leak detected (usage > 50% increase)
- Database connection failures

**Manual Triggers:**
- Critical feature broken
- Multiple customer complaints
- Data integrity issues
- Performance degradation > 2x

### Rollback Steps

1. **Immediate Action**
   ```bash
   # Revert to previous Docker image
   docker pull ghcr.io/papercups-io/papercups:<previous-tag>
   docker-compose up -d

   # OR revert git merge
   git revert <merge-commit-sha>
   git push origin master
   ```

2. **Verify Rollback**
   - [ ] Application starts
   - [ ] Health check passes
   - [ ] Error rate normalized
   - [ ] Critical features work

3. **Communication**
   - [ ] Notify engineering team
   - [ ] Update status page
   - [ ] Post in customer channels
   - [ ] Notify stakeholders

4. **Post-Rollback**
   - [ ] Document rollback reason
   - [ ] Identify root cause
   - [ ] Create fix plan
   - [ ] Schedule post-mortem

---

## Sign-Off Sheet

### Phase 0: Critical Fix
- [ ] Frontend Lead: _________________ Date: _______
- [ ] Build verified passing

### Phase 1: Pre-Merge
- [ ] QA Lead: _________________ Date: _______
- [ ] DevOps Lead: _________________ Date: _______
- [ ] Code Review Approved (2+ reviewers)

### Phase 2: Staging
- [ ] DevOps Lead: _________________ Date: _______
- [ ] Staging stable for 24+ hours

### Phase 3: Production Go/No-Go
- [ ] Engineering Manager: _________________ Date: _______
- [ ] CTO: _________________ Date: _______
- [ ] Product (if needed): _________________ Date: _______

### Phase 4: Post-Deployment
- [ ] Engineering Lead: _________________ Date: _______
- [ ] Deployment successful
- [ ] Documentation complete

---

## Notes & Issues

**Track issues and notes here during deployment:**

### Phase 0 Notes:
-

### Phase 1 Notes:
-

### Phase 2 Notes:
-

### Phase 3 Notes:
-

### Phase 4 Notes:
-

---

**Document Version:** 1.0
**Last Updated:** 2025-11-08
**Next Review:** After each phase completion
