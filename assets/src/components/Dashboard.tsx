import React, {useEffect, useRef, useState} from 'react';
import {
  useLocation,
  Switch,
  Redirect,
  Route,
  Link,
  RouteComponentProps,
} from 'react-router-dom';
import {Helmet} from 'react-helmet';
import {Box, Flex} from 'theme-ui';
import {ChatWidget, Papercups} from '@papercups-io/chat-widget';
// import {Storytime} from '../lib/storytime'; // For testing
import {Storytime} from '@papercups-io/storytime';
import {colors, Layout, Menu, Sider} from './common';
import {
  ApiOutlined,
  CodeOutlined,
  GlobalOutlined,
  LineChartOutlined,
  LogoutOutlined,
  MailOutlined,
  SettingOutlined,
  SmileOutlined,
  TeamOutlined,
  VideoCameraOutlined,
} from './icons';
import {
  BASE_URL,
  env,
  isDev,
  isEuEdition,
  isHostedProd,
  isStorytimeEnabled,
} from '../config';
import {SOCKET_URL} from '../socket';
import analytics from '../analytics';
import {
  DASHBOARD_COLLAPSED_SIDER_WIDTH,
  formatUserExternalId,
  getBrowserVisibilityInfo,
  hasValidStripeKey,
  isWindowHidden,
} from '../utils';
import {Account, User} from '../types';
import {useAuth} from './auth/AuthProvider';
import {SocketProvider, SocketContext} from './auth/SocketProvider';
import AccountOverview from './settings/AccountOverview';
import TeamOverview from './settings/TeamOverview';
import UserProfile from './settings/UserProfile';
import ChatWidgetSettings from './settings/ChatWidgetSettings';
import {
  ConversationsContext,
  ConversationsProvider,
  useConversations,
} from './conversations/ConversationsProvider';
import NotificationsProvider from './conversations/NotificationsProvider';
import IntegrationsOverview from './integrations/IntegrationsOverview';
import SlackReplyIntegrationDetails from './integrations/SlackReplyIntegrationDetails';
import SlackSyncIntegrationDetails from './integrations/SlackSyncIntegrationDetails';
import SlackIntegrationDetails from './integrations/SlackIntegrationDetails';
import GmailIntegrationDetails from './integrations/GmailIntegrationDetails';
import GoogleSheetsIntegrationDetails from './integrations/GoogleSheetsIntegrationDetails';
import GoogleIntegrationDetails from './integrations/GoogleIntegrationDetails';
import MattermostIntegrationDetails from './integrations/MattermostIntegrationDetails';
import TwilioIntegrationDetails from './integrations/TwilioIntegrationDetails';
import GithubIntegrationDetails from './integrations/GithubIntegrationDetails';
import HubspotIntegrationDetails from './integrations/HubspotIntegrationDetails';
import IntercomIntegrationDetails from './integrations/IntercomIntegrationDetails';
import BillingOverview from './billing/BillingOverview';
import CustomersPage from './customers/CustomersPage';
import CustomerDetailsPage from './customers/CustomerDetailsPage';
import CustomerDetailsPageV2 from './customers/CustomerDetailsPageV2';
import SessionsOverview from './sessions/SessionsOverview';
import InstallingStorytime from './sessions/InstallingStorytime';
import LiveSessionViewer from './sessions/LiveSessionViewer';
import ReportingDashboard from './reporting/ReportingDashboard';
import CompaniesPage from './companies/CompaniesPage';
import CreateCompanyPage from './companies/CreateCompanyPage';
import UpdateCompanyPage from './companies/UpdateCompanyPage';
import CompanyDetailsPage from './companies/CompanyDetailsPage';
import GettingStarted from './getting-started/GettingStarted';
import TagsOverview from './tags/TagsOverview';
import TagDetailsPage from './tags/TagDetailsPage';
import IssuesOverview from './issues/IssuesOverview';
import IssueDetailsPage from './issues/IssueDetailsPage';
import NotesOverview from './notes/NotesOverview';
import PersonalApiKeysPage from './developers/PersonalApiKeysPage';
import EventSubscriptionsPage from './developers/EventSubscriptionsPage';
import EmailTemplateBuilder from './developers/EmailTemplateBuilder';
import LambdaDetailsPage from './lambdas/LambdaDetailsPage';
import LambdasOverview from './lambdas/LambdasOverview';
import CannedResponsesOverview from './canned-responses/CannedResponsesOverview';
import ForwardingAddressSettings from './settings/ForwardingAddressSettings';
import InboxesDashboard from './inboxes/InboxesDashboard';

const {
  REACT_APP_ADMIN_ACCOUNT_ID = 'eb504736-0f20-4978-98ff-1a82ae60b266',
} = env;

const TITLE_FLASH_INTERVAL = 2000;

const shouldDisplayChat = (pathname: string) => {
  return isHostedProd && pathname !== '/settings/chat-widget';
};

const getSectionKey = (pathname: string) => {
  if (pathname.startsWith('/companies')) {
    return ['customers', 'companies'];
  } else if (pathname.startsWith('/customers')) {
    return ['customers', 'people'];
  } else if (pathname.startsWith('/tags')) {
    return ['customers', 'tags'];
  } else if (pathname.startsWith('/notes')) {
    return ['customers', 'notes'];
  } else if (pathname.startsWith('/functions')) {
    return ['developers', 'functions'];
  } else if (pathname.startsWith('/inboxes')) {
    return ['conversations', ...pathname.split('/').slice(2)];
  } else {
    return pathname.split('/').slice(1); // Slice off initial slash
  }
};

const useWindowVisibility = (d?: Document) => {
  const doc = d || document || window.document;
  const [isWindowVisible, setWindowVisible] = useState(!isWindowHidden(doc));

  useEffect(() => {
    const {event} = getBrowserVisibilityInfo(doc);
    const handler = () => setWindowVisible(!isWindowHidden(doc));

    if (!event) {
      return;
    }

    doc.addEventListener(event, handler, false);

    return () => doc.removeEventListener(event, handler);
  }, [doc]);

  return isWindowVisible;
};

const ChatWithUs = ({
  currentUser,
  account,
}: {
  currentUser: User;
  account?: Account | null;
}) => {
  if (isEuEdition) {
    return (
      <ChatWidget
        token={REACT_APP_ADMIN_ACCOUNT_ID}
        accountId={REACT_APP_ADMIN_ACCOUNT_ID}
        title="Need help with anything?"
        subtitle="Ask us in the chat window below 😊"
        greeting="Hi there! Send us a message and we'll get back to you as soon as we can."
        primaryColor="#1890ff"
        hideToggleButton
        baseUrl="https://app.papercups-eu.io"
        customer={{
          external_id: formatUserExternalId(currentUser),
          email: currentUser.email,
          metadata: {
            company_name: account?.company_name,
            subscription_plan: account?.subscription_plan,
            edition: 'EU',
          },
        }}
      />
    );
  }

  return (
    <ChatWidget
      token={REACT_APP_ADMIN_ACCOUNT_ID}
      accountId={REACT_APP_ADMIN_ACCOUNT_ID}
      title="Need help with anything?"
      subtitle="Ask us in the chat window below 😊"
      greeting="Hi there! Send us a message and we'll get back to you as soon as we can."
      primaryColor="#1890ff"
      hideToggleButton
      customer={{
        external_id: formatUserExternalId(currentUser),
        email: currentUser.email,
        metadata: {
          company_name: account?.company_name,
          subscription_plan: account?.subscription_plan,
          edition: 'US',
        },
      }}
    />
  );
};

// TODO: not sure if this is the best way to handle this, but the goal
// of this component is to flash the number of unread messages in the
// tab (i.e. HTML title) so users can see when new messages arrive
const DashboardHtmlHead = ({totalNumUnread}: {totalNumUnread: number}) => {
  const doc = document || window.document;
  const [htmlTitle, setHtmlTitle] = useState('Papercups');
  const isWindowVisible = useWindowVisibility(doc);
  const timer = useRef<any>();

  const hasDefaultTitle = (title: string) => title.startsWith('Papercups');

  const toggleNotificationMessage = () => {
    if (totalNumUnread > 0 && hasDefaultTitle(htmlTitle) && !isWindowVisible) {
      setHtmlTitle(
        `(${totalNumUnread}) New message${totalNumUnread === 1 ? '' : 's'}!`
      );
    } else {
      setHtmlTitle('Papercups');
    }
  };

  useEffect(() => {
    const shouldToggle =
      totalNumUnread > 0 && (!isWindowVisible || !hasDefaultTitle(htmlTitle));

    if (shouldToggle) {
      timer.current = setTimeout(
        toggleNotificationMessage,
        TITLE_FLASH_INTERVAL
      );
    } else {
      clearTimeout(timer.current);
    }

    return () => clearTimeout(timer.current);
  });

  return (
    <Helmet defer={false}>
      <title>{totalNumUnread ? htmlTitle : 'Papercups'}</title>
    </Helmet>
  );
};

const Dashboard = (props: RouteComponentProps) => {
  const auth = useAuth();
  const {pathname} = useLocation();
  const {unread} = useConversations();

  const {currentUser, account} = auth;
  const isAdminUser = currentUser?.role === 'admin';

  const [section, key] = getSectionKey(pathname);
  const totalNumUnread = unread.conversations.open || 0;
  const shouldDisplayBilling = hasValidStripeKey();
  const shouldHighlightInbox =
    totalNumUnread > 0 && section !== 'conversations';

  const logout = () => auth.logout().then(() => props.history.push('/login'));

  useEffect(() => {
    if (currentUser && currentUser.id) {
      const {email} = currentUser;
      const id = formatUserExternalId(currentUser);

      analytics.identify(id, email);
    }

    if (isStorytimeEnabled && currentUser) {
      const {email} = currentUser;
      // TODO: figure out a better way to initialize this?
      const storytime = Storytime.init({
        accountId: REACT_APP_ADMIN_ACCOUNT_ID,
        baseUrl: BASE_URL,
        debug: isDev,
        customer: {
          email,
          external_id: formatUserExternalId(currentUser),
        },
      });

      return () => storytime.finish();
    }
  }, [currentUser]);

  return (
    <Layout>
      <DashboardHtmlHead totalNumUnread={totalNumUnread} />

      <Sider
        width={DASHBOARD_COLLAPSED_SIDER_WIDTH}
        collapsed={true}
        style={{
          overflow: 'auto',
          height: '100vh',
          position: 'fixed',
          left: 0,
          color: colors.white,
        }}
      >
        <Flex sx={{flexDirection: 'column', height: '100%'}}>
          <Box py={3} sx={{flex: 1}}>
            <Menu selectedKeys={[section, key]} mode="inline" theme="dark">
              {isAdminUser && (
                <Menu.Item
                  key="getting-started"
                  icon={<GlobalOutlined />}
                  title="Getting started"
                >
                  <Link to="/getting-started">Getting started</Link>
                </Menu.Item>
              )}

              <Menu.Item
                danger={shouldHighlightInbox}
                key="conversations"
                icon={<MailOutlined />}
                title={`Inbox (${totalNumUnread})`}
              >
                <Link to="/conversations/all">Inbox ({totalNumUnread})</Link>
              </Menu.Item>

              {isAdminUser && (
                <Menu.Item
                  title="Integrations"
                  icon={<ApiOutlined />}
                  key="integrations"
                >
                  <Link to="/integrations">Integrations</Link>
                </Menu.Item>
              )}

              <Menu.SubMenu
                key="customers"
                icon={<TeamOutlined />}
                title="Customers"
              >
                <Menu.Item key="people">
                  <Link to="/customers">People</Link>
                </Menu.Item>
                <Menu.Item key="companies">
                  <Link to="/companies">Companies</Link>
                </Menu.Item>
                <Menu.Item key="tags">
                  <Link to="/tags">Tags</Link>
                </Menu.Item>
                <Menu.Item key="issues">
                  <Link to="/issues">Issues</Link>
                </Menu.Item>
                <Menu.Item key="notes">
                  <Link to="/notes">Notes</Link>
                </Menu.Item>
              </Menu.SubMenu>

              <Menu.Item
                title="Reporting"
                icon={<LineChartOutlined />}
                key="reporting"
              >
                <Link to="/reporting">Reporting</Link>
              </Menu.Item>

              {isAdminUser && (
                <Menu.SubMenu
                  key="developers"
                  icon={<CodeOutlined />}
                  title="Developers"
                >
                  <Menu.Item key="personal-api-keys">
                    <Link to="/developers/personal-api-keys">API keys</Link>
                  </Menu.Item>
                  <Menu.Item key="event-subscriptions">
                    <Link to="/developers/event-subscriptions">
                      Event subscriptions
                    </Link>
                  </Menu.Item>
                  <Menu.Item key="functions">
                    <Link to="/functions">Functions</Link>
                  </Menu.Item>
                </Menu.SubMenu>
              )}

              {isAdminUser && (
                <Menu.SubMenu
                  key="sessions"
                  icon={<VideoCameraOutlined />}
                  title="Sessions"
                >
                  <Menu.Item key="list">
                    <Link to="/sessions/list">Live sessions</Link>
                  </Menu.Item>
                  <Menu.Item key="setup">
                    <Link to="/sessions/setup">Set up Storytime</Link>
                  </Menu.Item>
                </Menu.SubMenu>
              )}

              {isAdminUser ? (
                <Menu.SubMenu
                  key="settings"
                  icon={<SettingOutlined />}
                  title="Settings"
                >
                  <Menu.Item key="account">
                    <Link to="/settings/account">Account</Link>
                  </Menu.Item>
                  <Menu.Item key="team">
                    <Link to="/settings/team">My team</Link>
                  </Menu.Item>
                  <Menu.Item key="profile">
                    <Link to="/settings/profile">My profile</Link>
                  </Menu.Item>
                  <Menu.Item key="inboxes" title="Inboxes">
                    <Link to="/inboxes">Inboxes</Link>
                  </Menu.Item>
                  <Menu.Item key="saved-replies">
                    <Link to="/settings/saved-replies">Saved replies</Link>
                  </Menu.Item>
                  {shouldDisplayBilling && (
                    <Menu.Item key="billing">
                      <Link to="/settings/billing">Billing</Link>
                    </Menu.Item>
                  )}
                </Menu.SubMenu>
              ) : (
                <Menu.SubMenu
                  key="settings"
                  icon={<SettingOutlined />}
                  title="Settings"
                >
                  <Menu.Item key="profile">
                    <Link to="/settings/profile">My profile</Link>
                  </Menu.Item>
                  <Menu.Item key="saved-replies">
                    <Link to="/settings/saved-replies">Saved replies</Link>
                  </Menu.Item>
                </Menu.SubMenu>
              )}
            </Menu>
          </Box>

          <Box py={3}>
            <Menu mode="inline" theme="dark" selectable={false}>
              {shouldDisplayChat(pathname) && (
                <Menu.Item
                  title="Chat with us!"
                  icon={<SmileOutlined />}
                  key="chat"
                  onClick={Papercups.toggle}
                >
                  Chat with us!
                </Menu.Item>
              )}
              <Menu.Item
                title="Log out"
                icon={<LogoutOutlined />}
                key="logout"
                onClick={logout}
              >
                Log out
              </Menu.Item>
            </Menu>
          </Box>
        </Flex>
      </Sider>

      <Layout
        style={{
          marginLeft: DASHBOARD_COLLAPSED_SIDER_WIDTH,
          background: colors.white,
        }}
      >
        <Switch>
          <Route path="/getting-started" component={GettingStarted} />

          {/* Temporary redirect routes to point from /accounts/* to /settings/* */}
          <Redirect from="/account/overview" to="/settings/overview" />
          <Redirect from="/account/team" to="/settings/team" />
          <Redirect from="/account/profile" to="/settings/profile" />
          <Redirect
            from="/account/getting-started"
            to="/settings/chat-widget"
          />
          <Redirect from="/account*" to="/settings*" />
          <Redirect from="/billing" to="/settings/billing" />
          <Redirect from="/saved-replies" to="/settings/saved-replies" />

          <Route path="/settings/account" component={AccountOverview} />
          <Route path="/settings/team" component={TeamOverview} />
          <Route path="/settings/profile" component={UserProfile} />
          <Route
            path="/settings/saved-replies"
            component={CannedResponsesOverview}
          />
          <Route
            path="/settings/email-forwarding"
            component={ForwardingAddressSettings}
          />
          <Route path="/settings/chat-widget" component={ChatWidgetSettings} />
          {shouldDisplayBilling && (
            <Route path="/settings/billing" component={BillingOverview} />
          )}
          <Route path="/settings*" component={AccountOverview} />
          <Route path="/v1/customers/:id" component={CustomerDetailsPage} />
          <Route path="/customers/:id" component={CustomerDetailsPageV2} />
          <Route path="/customers" component={CustomersPage} />
          <Route path="/companies/new" component={CreateCompanyPage} />
          <Route path="/companies/:id/edit" component={UpdateCompanyPage} />
          <Route path="/companies/:id" component={CompanyDetailsPage} />
          <Route path="/companies" component={CompaniesPage} />
          <Route
            path="/integrations/slack/reply"
            component={SlackReplyIntegrationDetails}
          />
          <Route
            path="/integrations/slack/support"
            component={SlackSyncIntegrationDetails}
          />
          <Route
            path="/integrations/slack"
            component={SlackIntegrationDetails}
          />
          <Route
            path="/integrations/google/gmail"
            component={GmailIntegrationDetails}
          />
          <Route
            path="/integrations/google/sheets"
            component={GoogleSheetsIntegrationDetails}
          />
          <Route
            path="/integrations/google"
            component={GoogleIntegrationDetails}
          />
          <Route
            path="/integrations/mattermost"
            component={MattermostIntegrationDetails}
          />
          <Route
            path="/integrations/twilio"
            component={TwilioIntegrationDetails}
          />
          <Route
            path="/integrations/github"
            component={GithubIntegrationDetails}
          />
          <Route
            path="/integrations/hubspot"
            component={HubspotIntegrationDetails}
          />
          <Route
            path="/integrations/intercom"
            component={IntercomIntegrationDetails}
          />
          <Route path="/integrations/:type" component={IntegrationsOverview} />
          <Route path="/integrations" component={IntegrationsOverview} />
          <Route path="/integrations*" component={IntegrationsOverview} />
          <Route
            path="/developers/personal-api-keys"
            component={PersonalApiKeysPage}
          />
          <Route
            path="/developers/event-subscriptions"
            component={EventSubscriptionsPage}
          />
          <Route
            path="/developers/_templates"
            component={EmailTemplateBuilder}
          />
          <Route path="/functions/:id" component={LambdaDetailsPage} />
          <Route path="/functions" component={LambdasOverview} />
          <Route path="/reporting" component={ReportingDashboard} />
          <Route path="/sessions/live/:session" component={LiveSessionViewer} />
          <Route path="/sessions/list" component={SessionsOverview} />
          <Route path="/sessions/setup" component={InstallingStorytime} />
          <Route path="/sessions*" component={SessionsOverview} />
          <Route path="/tags/:id" component={TagDetailsPage} />
          <Route path="/tags" component={TagsOverview} />
          <Route path="/issues/:id" component={IssueDetailsPage} />
          <Route path="/issues" component={IssuesOverview} />
          <Route path="/notes" component={NotesOverview} />
          <Route path="/conversations*" component={InboxesDashboard} />
          <Route path="/inboxes*" component={InboxesDashboard} />
          <Route path="*" render={() => <Redirect to="/conversations/all" />} />
        </Switch>
      </Layout>

      {currentUser && shouldDisplayChat(pathname) && (
        <ChatWithUs currentUser={currentUser} account={account} />
      )}
    </Layout>
  );
};

const DashboardWrapper = (props: RouteComponentProps) => {
  const {refresh} = useAuth();

  return (
    <SocketProvider url={SOCKET_URL} refresh={refresh}>
      <SocketContext.Consumer>
        {({socket}) => {
          return (
            <ConversationsProvider>
              <ConversationsContext.Consumer>
                {({onNewMessage, onNewConversation, onConversationUpdated}) => {
                  return (
                    <NotificationsProvider
                      socket={socket}
                      onNewMessage={onNewMessage}
                      onNewConversation={onNewConversation}
                      onConversationUpdated={onConversationUpdated}
                    >
                      <Dashboard {...props} />
                    </NotificationsProvider>
                  );
                }}
              </ConversationsContext.Consumer>
            </ConversationsProvider>
          );
        }}
      </SocketContext.Consumer>
    </SocketProvider>
  );
};

export default DashboardWrapper;
