import React from 'react';
import {Box, Flex} from 'theme-ui';
import {
  colors,
  Button,
  Menu,
  TextArea,
  Upload,
  UploadChangeParam,
  UploadFile,
  Tooltip,
} from '../common';
import {Message, MessageType, User} from '../../types';
import {InfoCircleOutlined, PaperClipOutlined} from '../icons';
import {env} from '../../config';
import {DashboardShortcutsRenderer} from './DashboardShortcutsModal';

const {REACT_APP_FILE_UPLOADS_ENABLED} = env;

const fileUploadsEnabled = (accountId?: string) => {
  const enabled = REACT_APP_FILE_UPLOADS_ENABLED || '';

  switch (enabled) {
    case '1':
    case 'true':
      return true;
    default:
      return accountId && accountId.length && enabled.includes(accountId);
  }
};

const AttachFileButton = ({
  fileList,
  currentUser,
  onUpdateFileList,
}: {
  fileList: any;
  currentUser: User;
  onUpdateFileList: (info: UploadChangeParam) => void;
}) => {
  // Antd takes a url to make the post request and data that gets added to the request
  // (See https://ant.design/components/upload/ for more information)
  const action = '/api/upload';
  // TODO: figure out a better way to set these!
  const data = {account_id: currentUser.account_id, user_id: currentUser.id};

  return (
    <Upload
      className="AttachFileButton"
      action={action}
      onChange={onUpdateFileList}
      data={data}
      fileList={fileList}
    >
      <Button icon={<PaperClipOutlined />} size="small">
        Attach a file
      </Button>
    </Upload>
  );
};

const ConversationFooter = ({
  sx = {},
  onSendMessage,
  currentUser,
}: {
  sx?: any;
  onSendMessage: (message: Partial<Message>) => void;
  currentUser?: User | null;
}) => {
  const [message, setMessage] = React.useState<string>('');
  const [fileList, setFileList] = React.useState<Array<UploadFile>>([]);
  const [messageType, setMessageType] = React.useState<MessageType>('reply');
  const [isSendDisabled, setSendDisabled] = React.useState<boolean>(false);

  const isPrivateNote = messageType === 'note';
  const accountId = currentUser?.account_id;
  const shouldDisplayUploadButton = fileUploadsEnabled(accountId);

  const handleMessageChange = (e: React.ChangeEvent<HTMLTextAreaElement>) =>
    setMessage(e.target.value);

  const handleSetMessageType = ({key}: any) => setMessageType(key);

  const handleKeyDown = (e: any) => {
    const {key, metaKey} = e;
    // Not sure what the best UX is here, but we currently allow
    // sending the message by pressing "cmd/metaKey + Enter"
    if (metaKey && key === 'Enter') {
      handleSendMessage();
    }
  };

  const handleSendMessage = (e?: any) => {
    e && e.preventDefault();

    onSendMessage({
      body: message,
      type: messageType,
      private: isPrivateNote,
      file_ids: fileList.map((f) => f.response?.data?.id),
    });

    setFileList([]);
    setMessage('');
  };

  const onUpdateFileList = ({file, fileList, event}: UploadChangeParam) => {
    setFileList(fileList);

    // Disable send button when file upload is in progress
    if (event) {
      setSendDisabled(true);
    }

    // Enable send button again when the server has responded
    if (file && file.response) {
      setSendDisabled(false);
    }
  };

  return (
    <Box style={{flex: '0 0 auto'}}>
      <Box
        sx={{
          bg: colors.white,
          px: 4,
          pt: 0,
          pb: 4,
          ...sx,
        }}
      >
        <Box
          px={2}
          pb={2}
          pt={1}
          sx={{
            background: isPrivateNote ? colors.noteSecondary : colors.white,
            border: '1px solid #f5f5f5',
            borderRadius: 4,
            boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 8px',
          }}
        >
          <form onSubmit={handleSendMessage}>
            <Box px={2} mb={2} sx={{position: 'relative'}}>
              <Menu
                mode="horizontal"
                style={{
                  border: 'none',
                  lineHeight: '36px',
                  fontWeight: 500,
                  background: 'transparent',
                  color: colors.secondary,
                }}
                defaultSelectedKeys={['reply']}
                selectedKeys={[messageType]}
                onClick={handleSetMessageType}
              >
                <Menu.Item
                  key="reply"
                  style={{padding: '0 4px', marginRight: 20}}
                >
                  Reply
                </Menu.Item>
                <Menu.Item
                  key="note"
                  style={{padding: '0 4px', marginRight: 20}}
                >
                  Note
                </Menu.Item>
              </Menu>

              <Box sx={{position: 'absolute', right: 0, top: 0, opacity: 0.8}}>
                <DashboardShortcutsRenderer>
                  {(handleOpenModal) => (
                    <Tooltip placement="top" title="View keyboard shortcuts">
                      <Button
                        type="text"
                        size="small"
                        icon={<InfoCircleOutlined />}
                        onClick={handleOpenModal}
                      />
                    </Tooltip>
                  )}
                </DashboardShortcutsRenderer>
              </Box>
            </Box>

            <Box mb={2}>
              {/* NB: we use the `key` prop to auto-focus the textarea when toggling `messageType` */}
              <TextArea
                key={messageType}
                className="TextArea--transparent"
                placeholder={
                  isPrivateNote
                    ? 'Type a private note here'
                    : 'Type your reply here'
                }
                autoSize={{minRows: 2, maxRows: 4}}
                autoFocus
                value={message}
                onKeyDown={handleKeyDown}
                onChange={handleMessageChange}
              />
            </Box>
            {shouldDisplayUploadButton ? (
              <Flex
                sx={{
                  alignItems: 'flex-end',
                  justifyContent: 'space-between',
                }}
              >
                {currentUser && (
                  <AttachFileButton
                    fileList={fileList}
                    currentUser={currentUser}
                    onUpdateFileList={onUpdateFileList}
                  />
                )}
                <Button
                  type="primary"
                  htmlType="submit"
                  disabled={isSendDisabled}
                >
                  Send
                </Button>
              </Flex>
            ) : (
              <Flex sx={{justifyContent: 'flex-end'}}>
                <Button
                  type="primary"
                  htmlType="submit"
                  disabled={isSendDisabled}
                >
                  Send
                </Button>
              </Flex>
            )}
          </form>
        </Box>
      </Box>
    </Box>
  );
};

export default ConversationFooter;
