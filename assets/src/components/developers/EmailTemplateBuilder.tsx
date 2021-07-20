import React from 'react';
import {Box, Flex} from 'theme-ui';
import MonacoEditor from './MonacoEditor';
import {getIframeContents} from './email/html';

const DEFAULT_CODE_VALUE = `
const Email = () => {
  return (
    <Layout background="#f9f9f9">
      <Container minWidth={320} maxWidth={640}>
        <Content bordered theme={{color: "#1890ff"}}>
          <Body>
            <Paragraph>
              Hey there!
            </Paragraph>
            <Paragraph>
              Papercups v2.0 is out! Here are the biggest changes...
            </Paragraph>

            <H2>
              Slack Integration
            </H2>
            <Paragraph>
              Our Slack integration allows you to...
            </Paragraph>
          </Body>
        </Content>
      </Container>
    </Layout>
  );
};
`;

export class EmailTemplateBuilder extends React.Component<any, any> {
  iframe: HTMLIFrameElement | null = null;
  monaco: any | null = null;

  handleUpdateIframe = () => {
    const code = this.monaco?.getValue();
    const doc = this.iframe?.contentDocument;

    if (!code || !doc) {
      return;
    }

    const contents = getIframeContents({js: code});

    doc.open();
    doc.write(contents);
    doc.close();
  };

  getEmailHtml = (): string | null => {
    const el = this.iframe?.contentWindow?.document?.getElementById('email');

    return el?.innerHTML ?? null;
  };

  handleEditorMounted = (editor: any) => {
    this.monaco = editor;
  };

  render() {
    return (
      <Flex sx={{width: '100%', minHeight: '100%', flex: 1}}>
        <Box sx={{flex: 1}}>
          <MonacoEditor
            height="100%"
            width="100%"
            defaultLanguage="javascript"
            defaultValue={DEFAULT_CODE_VALUE}
            options={{tabSize: 2}}
            onMount={this.handleEditorMounted}
            onValidate={this.handleUpdateIframe}
            onSave={this.handleUpdateIframe}
          />
        </Box>
        <Box sx={{flex: 1.2}}>
          <iframe
            title="email"
            style={{height: '100%', width: '100%', border: 'none'}}
            ref={(el) => (this.iframe = el)}
          />
        </Box>
      </Flex>
    );
  }
}

export default EmailTemplateBuilder;
