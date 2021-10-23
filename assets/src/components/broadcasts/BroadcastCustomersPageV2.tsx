import React from 'react';
import {Box, Flex} from 'theme-ui';

import MonacoEditor from '../developers/MonacoEditor';
import {
  Button,
  Checkbox,
  Divider,
  Input,
  Paragraph,
  Select,
  Text,
  Title,
  notification,
  TextArea,
  Upload,
} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import {Broadcast, Customer} from '../../types';
import {Link, RouteComponentProps} from 'react-router-dom';
import {formatServerError, sleep} from '../../utils';
import {ArrowLeftOutlined} from '../icons';
import Cache from '../../storage-v2';
import DynamicTable from '../developers/DynamicTable';
import DynamicSpreadsheet from '../developers/DynamicSpreadsheet';

const DEFAULT_SQL_VALUE = `
-- select u.email, p.display_name as name
--   from users u join user_profiles p on u.id = p.user_id
--   where u.id = 1;

select u.id, p.display_name as name, p.full_name, u.email, count(m.id) as num_messages
  from users u
  join user_profiles p on u.id = p.user_id
  join messages m on m.user_id = u.id
  where m.inserted_at > (current_date - interval '30' day)
  group by u.id, p.display_name, p.full_name
  order by num_messages desc;
`;

const DEFAULT_JS_VALUE = `
const process = (records) => {
  return records
    .filter(record => {
      return record.num_messages > 10 && record.name && !record.full_name;
    })
    .map(record => {
      const {full_name: fullName, email} = record;

      if (fullName && fullName.length) {
        return record;
      } else {
        const [name, domain] = email.split('@');
        const guess = name
          .split('.')
          .map(str => str.slice(0, 1).toUpperCase().concat(str.slice(1)))
          .join(' ')
          .replace(/[^A-Za-z]/g, '');

        return {...record, full_name: guess};
      }
    });
};
`;

type Props = RouteComponentProps<{id: string}>;
type State = {
  broadcast: Broadcast | null;
  mode: string;
  hostname: string;
  database: string;
  username: string;
  password: string;
  databaseUri: string;
  isSslEnabled: boolean;
  isRunning: boolean;
  googleSheetId: string;
  googleSheetUrl: string;
  csv: string;
  data: Array<any>;
  results: Array<any>;
};

const CACHE_KEY = 'BroadcastCustomersPageV2';

export class BroadcastCustomersPageV2 extends React.Component<Props, State> {
  editors: {sql: any | null; js: any | null} = {sql: null, js: null};
  cache: Cache = new Cache({type: 'local'});

  constructor(props: Props) {
    super(props);

    const cachedDbState = this.cache.get(CACHE_KEY, {});
    const {
      mode = 'sql',
      hostname = 'localhost',
      database = 'chat_api_dev',
      username = '',
      password = '',
      databaseUri = 'ecto://postgres:postgres@localhost/chat_api_dev',
      isSslEnabled = false,
      googleSheetId = '1LbdDpXARNT5I3qOUsc7VW8kLU_LZt5zRSscBgJHR8ik',
      googleSheetUrl = '',
      csv = '',
    } = cachedDbState;

    this.state = {
      broadcast: null,
      mode,
      // SQL
      hostname,
      database,
      username,
      password,
      databaseUri,
      isSslEnabled,
      isRunning: false,
      // Google Sheets
      googleSheetId,
      googleSheetUrl,
      csv,
      data: [],
      results: [],
    };
  }

  async componentDidMount() {
    const {id: broadcastId} = this.props.match.params;
    const broadcast = await API.fetchBroadcast(broadcastId);

    this.setState({broadcast});
  }

  handleSqlEditorMounted = async (editor: any) => {
    this.editors.sql = editor;

    this.editors.sql.addAction({
      id: 'save',
      label: 'Save',
      keybindings: [2048 | 3], // [KeyMod.CtrlCmd | KeyCode.Enter]
      contextMenuGroupId: 'navigation',
      contextMenuOrder: 2,
      run: () => {
        this.handleRunSql();
      },
    });

    return this.handleRunSql().then(() => this.handleApplyJsProcessing());
  };

  handleJsEditorMounted = (editor: any) => {
    this.editors.js = editor;
  };

  filterResultsByJs = (results: Array<any>) => {
    try {
      // TODO: support typescript?
      const js = this.editors.js?.getValue();
      // Assumes the existence of a `process` function
      // eslint-disable-next-line
      return eval(js.concat('\nprocess(results)'));
    } catch (e) {
      return results;
    }
  };

  handleApplyJsProcessing = () => {
    const {data = []} = this.state;

    this.setState({results: this.filterResultsByJs(data)});
  };

  fetchCustomersFromGoogleSheet = async () => {
    try {
      this.setState({isRunning: true});

      const {googleSheetId, googleSheetUrl} = this.state;

      if (!googleSheetId && !googleSheetUrl) {
        return null;
      }

      const filter = googleSheetUrl
        ? {url: googleSheetUrl}
        : {id: googleSheetId};

      const data = await API.fetchGoogleSheet(filter);

      this.setState({data});
    } catch (err) {
      logger.error(
        'Failed to import data from Google Sheet:',
        formatServerError(err)
      );
    } finally {
      this.setState({isRunning: false});
    }
  };

  handleCsvUploadEvent = ({file = {}}: any) => {
    if (!file || file?.status !== 'done') {
      return;
    }

    const {response = {}} = file;
    const {data = []} = response;

    if (data && Array.isArray(data) && data.length > 0) {
      this.setState({data, csv: response._csv || ''});
    }
  };

  setStateWithCache = (updates: any) => {
    const cached = this.cache.get(CACHE_KEY, {});

    this.setState(updates, () =>
      this.cache.set(CACHE_KEY, {...cached, ...updates})
    );
  };

  getDefaultSql = (): string => {
    const cached = this.cache.get(CACHE_KEY, {});

    return cached?.sql ?? DEFAULT_SQL_VALUE;
  };

  getDefaultJavascript = (): string => {
    return DEFAULT_JS_VALUE;
  };

  cacheSqlCode = (sql: string) => {
    const cached = this.cache.get(CACHE_KEY, {});

    this.cache.set(CACHE_KEY, {...cached, sql});
  };

  handleEditResults = (data: any, metadata: any) => {
    this.setState({results: data});
  };

  handleImportCustomers = async () => {
    try {
      const {id: broadcastId} = this.props.match.params;
      const {results = []} = this.state;
      const isDryRun = false; // TODO: make this configurable
      const {data: customers} = await API.importCustomers({
        customers: results,
        dry: isDryRun,
      });

      const customerIds = customers.map((c: Customer) => c.id);
      // Separate this step from the importing data
      // TODO: add `is_subscribed` and `has_valid_email` fields to customers
      // (has_valid_email: nil indicates no check, vs false indicates invalid)
      await API.addCustomersToBroadcast(broadcastId, customerIds);

      notification.success({
        message: 'Done!',
        description: `${customers.length} customers successfully added to broadcast. Returning to broadcast...`,
        duration: 4, // 4 seconds
      });

      await sleep(1000);

      return this.props.history.push(`/broadcasts/${broadcastId}`);
    } catch (err) {
      logger.error('Failed to import customers:', formatServerError(err));
    }
  };

  handleRunSql = async () => {
    try {
      this.setState({isRunning: true});

      const {
        hostname,
        database,
        username,
        password,
        databaseUri,
        isSslEnabled,
      } = this.state;
      const sql = this.editors.sql?.getValue();

      if (!sql) {
        return;
      }

      const data = await API.runSqlQuery({
        query: sql,
        credentials: {
          hostname,
          database,
          username,
          password,
          uri: databaseUri,
          ssl: isSslEnabled,
        },
      });

      await sleep(1000);

      this.setState({data}, () => this.cacheSqlCode(sql));
    } catch (err) {
      const message = formatServerError(err);
      logger.error('Failed to run query:', err);
      notification.error({
        message: 'Failed to run query!',
        description: message,
      });
    } finally {
      this.setState({isRunning: false});
    }
  };

  render() {
    const {
      broadcast,
      mode,
      hostname,
      database,
      username,
      password,
      databaseUri,
      googleSheetId,
      googleSheetUrl,
      csv,
      isSslEnabled,
      isRunning,
      data = [],
      results = [],
    } = this.state;

    if (!broadcast) {
      return null;
    }

    const {id: broadcastId, name} = broadcast;

    // TODO: make editor and query results side by side instead of top/bottom
    return (
      <Flex sx={{flex: 1, flexDirection: 'column'}}>
        <Flex
          pl={3}
          pr={4}
          py={3}
          sx={{
            justifyContent: 'space-between',
            alignItems: 'center',
            borderBottom: '1px solid rgba(0,0,0,.06)',
          }}
        >
          <Box mr={3}>
            <Link to={`/broadcasts/${broadcastId}`}>
              <Button icon={<ArrowLeftOutlined />}>Back</Button>
            </Link>
          </Box>

          <Title level={4} style={{margin: 0}}>
            Select customers for {name}
          </Title>
        </Flex>

        <Flex
          sx={{
            flex: 1,
            width: '100%',
            // maxWidth: 720,
            // mx: 'auto',
          }}
        >
          <Flex
            sx={{
              flexDirection: 'column',
              flex: 1,
              // bg: 'rgb(250, 250, 250)',
              // borderRight: '1px solid rgba(0,0,0,.06)',
            }}
          >
            <Box
              p={3}
              sx={{
                borderBottom: '1px solid rgba(0,0,0,.06)',
                width: '100%',
                maxWidth: 720,
                mx: 'auto',
              }}
            >
              <Select
                style={{width: '100%'}}
                placeholder="Select import method"
                value={mode}
                size="large"
                onChange={(value: string) => {
                  this.setStateWithCache({mode: value});
                }}
                options={[
                  {value: 'sql', display: 'Import via SQL'},
                  {value: 'sheets', display: 'Import from Google Sheets'},
                  {value: 'csv', display: 'Import CSV'},
                ].map(({value, display}) => {
                  return {id: value, key: value, label: display, value};
                })}
              />
            </Box>

            {mode === 'csv' && (
              <Box
                p={3}
                sx={{
                  borderBottom: '1px solid rgba(0,0,0,.06)',
                  width: '100%',
                  maxWidth: 720,
                  mx: 'auto',
                }}
              >
                <Box mb={3}>
                  <label htmlFor="csv_content">CSV</label>
                  <TextArea
                    id="csv_content"
                    disabled
                    value={csv}
                    placeholder={
                      'name,email,company\nAlex,alex@papercups.io,Papercups'
                    }
                    autoSize={{minRows: 4, maxRows: 8}}
                  />
                </Box>

                <Box mt={4} mb={3}>
                  <Upload
                    style={{width: '100%'}}
                    className="UploadCsvButton"
                    action={'/api/csv'}
                    showUploadList={false}
                    onChange={this.handleCsvUploadEvent}
                  >
                    <Button type="primary" block loading={isRunning}>
                      {isRunning ? 'Uploading...' : 'Upload CSV'}
                    </Button>
                  </Upload>
                </Box>
              </Box>
            )}

            {mode === 'sheets' && (
              <Box
                p={3}
                sx={{
                  borderBottom: '1px solid rgba(0,0,0,.06)',
                  width: '100%',
                  maxWidth: 720,
                  mx: 'auto',
                }}
              >
                <Box>
                  <Title level={4}>Google Sheets</Title>
                </Box>
                <Box mb={3}>
                  <label htmlFor="google_sheet_id">Google Sheet ID</label>
                  <Input
                    id="google_sheet_id"
                    type="text"
                    value={googleSheetId}
                    placeholder="xxxxxx-x-xxxxxx-xxxxxxxxxxxx"
                    onChange={(e) =>
                      this.setStateWithCache({googleSheetId: e.target.value})
                    }
                  />
                </Box>

                <Box mb={3}>
                  <label htmlFor="google_sheet_url">Google Sheet URL</label>
                  <Input
                    id="google_sheet_url"
                    type="text"
                    value={googleSheetUrl}
                    placeholder="https://docs.google.com/spreadsheets/u/2/d/[GOOGLE_SHEET_ID]"
                    onChange={(e) =>
                      this.setStateWithCache({googleSheetUrl: e.target.value})
                    }
                  />
                </Box>

                <Box mt={4} mb={3}>
                  <Button
                    type="primary"
                    block
                    loading={isRunning}
                    onClick={this.fetchCustomersFromGoogleSheet}
                  >
                    {isRunning ? 'Importing...' : 'Import customers'}
                  </Button>
                </Box>
              </Box>
            )}

            {mode === 'sql' && (
              <Box
                p={3}
                sx={{
                  borderBottom: '1px solid rgba(0,0,0,.06)',
                  width: '100%',
                  maxWidth: 720,
                  mx: 'auto',
                }}
              >
                <Box>
                  <Title level={4}>Database credentials</Title>
                </Box>
                <Flex mb={3} mx={-2}>
                  <Box mx={2} sx={{flex: 1}}>
                    <label htmlFor="hostname">Host</label>
                    <Input
                      id="hostname"
                      type="text"
                      value={hostname}
                      placeholder="localhost"
                      onChange={(e) =>
                        this.setStateWithCache({hostname: e.target.value})
                      }
                    />
                  </Box>
                  <Box mx={2} sx={{flex: 1}}>
                    <label htmlFor="database">Database</label>
                    <Input
                      id="database"
                      type="text"
                      value={database}
                      placeholder="papercups"
                      onChange={(e) =>
                        this.setStateWithCache({database: e.target.value})
                      }
                    />
                  </Box>
                </Flex>
                <Flex mb={3} mx={-2}>
                  <Box mx={2} sx={{flex: 1}}>
                    <label htmlFor="username">Username</label>
                    <Input
                      id="username"
                      type="text"
                      value={username}
                      onChange={(e) =>
                        this.setStateWithCache({username: e.target.value})
                      }
                    />
                  </Box>
                  <Box mx={2} sx={{flex: 2}}>
                    <label htmlFor="password">Password</label>
                    <Input
                      id="password"
                      // TODO: allow toggle password
                      type="text"
                      value={password}
                      onChange={(e) =>
                        this.setStateWithCache({password: e.target.value})
                      }
                    />
                  </Box>
                  <Box mx={2} py={1} sx={{width: 120, alignSelf: 'flex-end'}}>
                    <Checkbox
                      checked={isSslEnabled}
                      onChange={(e) =>
                        this.setStateWithCache({
                          isSslEnabled: e.target.checked,
                        })
                      }
                    >
                      SSL enabled
                    </Checkbox>
                  </Box>
                </Flex>

                <Divider style={{marginTop: 16, marginBottom: 16}} />

                <Flex mb={3}>
                  <Box sx={{flex: 1}}>
                    <label htmlFor="database_uri">
                      <Text strong>
                        Alternatively, enter the full database URI:
                      </Text>
                    </label>
                    <Input
                      id="database_uri"
                      type="text"
                      value={databaseUri}
                      onChange={(e) =>
                        this.setStateWithCache({
                          databaseUri: e.target.value,
                        })
                      }
                    />
                  </Box>
                </Flex>
              </Box>
            )}
            {mode === 'sql' && (
              <Box sx={{width: '100%', maxWidth: 720, mx: 'auto'}}>
                <Box
                  sx={{
                    height: 320,
                    position: 'relative',
                    overflow: 'hidden',
                  }}
                >
                  <MonacoEditor
                    height="100%"
                    width="100%"
                    defaultLanguage="sql"
                    defaultValue={this.getDefaultSql()}
                    onMount={this.handleSqlEditorMounted}
                  />

                  <Box
                    px={2}
                    style={{position: 'absolute', top: 12, right: 16}}
                  >
                    <Button loading={isRunning} onClick={this.handleRunSql}>
                      {isRunning ? 'Running...' : 'Run query'}
                    </Button>
                  </Box>
                </Box>
                <Box>
                  <Button block loading={isRunning} onClick={this.handleRunSql}>
                    {isRunning ? 'Running...' : 'Run query'}
                  </Button>
                </Box>
              </Box>
            )}

            <Box my={4}>
              <Box
                p={3}
                sx={{
                  width: '100%',
                  maxWidth: 720,
                  mx: 'auto',
                }}
              >
                <Title level={4}>
                  Initial results {data.length ? `(${data.length})` : null}
                </Title>
                <Paragraph>
                  <Text type="secondary">
                    The initial data set you'll be working with. You can apply
                    filters, transformations, and manual edits below.
                  </Text>
                </Paragraph>
              </Box>

              <Box sx={{width: '100%', maxWidth: 960, mx: 'auto'}}>
                <DynamicTable data={data} />
              </Box>
            </Box>

            <Box sx={{width: '100%', maxWidth: 720, mx: 'auto'}}>
              <Box p={3}>
                <Title level={4}>
                  Apply custom filters and transformations
                </Title>
                <Paragraph>
                  <Text type="secondary">
                    Use JavaScript to apply filters and transformations to your
                    data set.
                  </Text>
                </Paragraph>
              </Box>

              <Box sx={{height: 400, position: 'relative', overflow: 'hidden'}}>
                <MonacoEditor
                  height="100%"
                  width="100%"
                  defaultLanguage="javascript"
                  defaultValue={this.getDefaultJavascript()}
                  onMount={this.handleJsEditorMounted}
                />

                <Box px={2} style={{position: 'absolute', top: 12, right: 16}}>
                  <Button
                    disabled={isRunning}
                    onClick={this.handleApplyJsProcessing}
                  >
                    Apply
                  </Button>
                </Box>
              </Box>
              <Box>
                <Button
                  block
                  disabled={isRunning}
                  onClick={this.handleApplyJsProcessing}
                >
                  Apply
                </Button>
              </Box>
            </Box>

            <Box my={4}>
              <Box
                p={3}
                sx={{
                  width: '100%',
                  maxWidth: 720,
                  mx: 'auto',
                }}
              >
                <Title level={4}>
                  Final results {results.length ? `(${results.length})` : null}
                </Title>
                <Paragraph>
                  <Text type="secondary">
                    Click on any cell below to perform any final edits your
                    contact list.
                  </Text>
                </Paragraph>
              </Box>

              <Box sx={{width: '100%', maxWidth: 960, mx: 'auto'}}>
                <DynamicSpreadsheet data={results} />
              </Box>
            </Box>

            <Box mb={5} sx={{width: '100%', maxWidth: 720, mx: 'auto'}}>
              <Button
                block
                type="primary"
                size="large"
                disabled={isRunning || results.length === 0}
                loading={isRunning}
                onClick={this.handleImportCustomers}
              >
                Import {results.length}{' '}
                {results.length === 1 ? 'customer' : 'customers'}
              </Button>
            </Box>
          </Flex>
        </Flex>
      </Flex>
    );
  }
}

export default BroadcastCustomersPageV2;
