import React from 'react';

import {Box, Flex} from 'theme-ui';
import {colors, Button, Menu, Popover, TextArea, Upload} from '../common';
import {Message, MessageType, User} from '../../types';
import '../../index.css';

import {PaperClipOutlined} from '../icons';
import {UploadChangeParam} from 'antd/lib/upload';
import {UploadFile} from 'antd/lib/upload/interface';
import {FRONTEND_BASE_URL} from '../../config';

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
  const [fileList, setFileList] = React.useState<UploadFile[]>([]);
  const [messageType, setMessageType] = React.useState<MessageType>('reply');
  const [disableSend, setDisableSend] = React.useState<boolean>(false);

  const isPrivateNote = messageType === 'note';

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
      upload_ids: fileList.map((f) => f.response?.data?.id),
    });

    setFileList([]);
    setMessage('');
  };

  //Antd takes a url to make the post request and data that gets added to the request https://ant.design/components/upload/
  const action = FRONTEND_BASE_URL + '/api/upload';
  const data = {account_id: currentUser?.account_id, user_id: currentUser?.id};
  const onUpdateFileList = (info: UploadChangeParam) => {
    const {file, fileList, event} = info;
    setFileList(fileList);

    //disable when file upload is in progress
    if (event) {
      setDisableSend(true);
    }

    //enable when the server has responded
    if (file && file.response) {
      setDisableSend(false);
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
            background: isPrivateNote ? 'rgba(254,237,175,.4)' : colors.white,
            border: '1px solid #f5f5f5',
            borderRadius: 4,
            boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 8px',
          }}
        >
          <form onSubmit={handleSendMessage}>
            <Box px={2} mb={2}>
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
            <Flex
              sx={{
                alignItems: 'flex-end',
                justifyContent: 'space-between',
              }}
            >
              <Upload
                className="upload"
                action={action}
                onChange={onUpdateFileList}
                data={data}
                fileList={fileList}
              >
                <Button
                  icon={<PaperClipOutlined />}
                  type="ghost"
                  style={{border: 'none', background: 'none'}}
                ></Button>
              </Upload>
              <Button type="primary" htmlType="submit" disabled={disableSend}>
                Send
              </Button>
            </Flex>
          </form>
        </Box>
      </Box>
    </Box>
  );
};

export default ConversationFooter;
