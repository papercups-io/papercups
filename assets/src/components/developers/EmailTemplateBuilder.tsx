import React from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import {Box, Flex} from 'theme-ui';
// @ts-ignore
import {generateElement} from 'react-live';
import {MarkdownRenderer} from '../common';
import MonacoEditor from './MonacoEditor';
import {getIframeContents} from './email/html';
import {
  Layout,
  Container,
  Content,
  Body,
  Paragraph,
  H2,
  Variable,
} from './email/boilerplate';
import * as API from '../../api';
import logger from '../../logger';

const DEFAULT_CODE_VALUE = `
const Email = () => {
  return (
    <Layout background="#f9f9f9">
      <Container minWidth={320} maxWidth={640}>
        <Content bordered theme={{color: "#1890ff"}}>
          <Body>
            <Paragraph>
              Hey <Variable template="<%= name %>" />!
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

const MARKDOWN_CODE_VALUE = `
const Email = () => {
  return (
    <Layout background="#f9f9f9">
      <Container minWidth={320} maxWidth={640}>
        <Content bordered theme={{color: "#1890ff"}}>
          <Body>
            <Markdown source={__MARKDOWN__} />
          </Body>
        </Content>
      </Container>
    </Layout>
  );
};
`;

const EXAMPLE_MARKDOWN = `
Hey Alex! :wave:

Let's **try** out some _markdown_ :)

Here's a [link](https://papercups.io)!
`;

export class EmailTemplateBuilder extends React.Component<any, any> {
  iframe: HTMLIFrameElement | null = null;
  monaco: any | null = null;

  state = {mode: 'react', json: {name: 'Alex', company: 'Papercups'}};

  handleUpdateJson = (code?: string) => {
    if (!code) {
      return this.setState({json: {}});
    }

    try {
      this.setState({json: JSON.parse(code)});
    } catch (e) {
      //
    }
  };

  handleUpdateReactIframe = async () => {
    const code = this.monaco?.getValue();
    const doc = this.iframe?.contentDocument;

    if (!code || !doc) {
      return;
    }

    try {
      // TODO: instead of importing from react-live, just copy the files over?
      const Element = generateElement(
        {
          code: code.replace('const Email = ', ''),
          scope: {
            Layout,
            Container,
            Content,
            Body,
            Paragraph,
            H2,
            Variable,
          },
        },
        logger.error
      );

      const html = renderToStaticMarkup(<Element />);
      const contents = getIframeContents({html});
      const rendered = await API.renderEmailTemplate({
        html: contents,
        data: this.state.json,
      });

      doc.open();
      doc.write(rendered);
      doc.close();
    } catch (e) {
      logger.error(e);
    }
  };

  handleUpdateMarkdownIframe = async () => {
    const code = this.monaco?.getValue();
    const doc = this.iframe?.contentDocument;

    if (!code || !doc) {
      return;
    }

    try {
      // TODO: instead of importing from react-live, just copy the files over?
      const Element = generateElement(
        {
          code: MARKDOWN_CODE_VALUE.replace('const Email = ', ''),
          scope: {
            Layout,
            Container,
            Content,
            Body,
            Paragraph,
            H2,
            Variable,
            Markdown: MarkdownRenderer,
            __MARKDOWN__: code,
          },
        },
        logger.error
      );

      const html = renderToStaticMarkup(<Element />);
      const contents = getIframeContents({html});
      const rendered = await API.renderEmailTemplate({
        html: contents,
        data: this.state.json,
      });

      doc.open();
      doc.write(rendered);
      doc.close();
    } catch (e) {
      logger.error(e);
    }
  };

  getEmailHtml = (): string | null => {
    const el = this.iframe?.contentWindow?.document?.getElementById('email');

    return el?.innerHTML ?? null;
  };

  handleEditorMounted = (editor: any) => {
    this.monaco = editor;

    if (this.state.mode === 'react') {
      this.handleUpdateReactIframe();
    } else {
      this.handleUpdateMarkdownIframe();
    }
  };

  render() {
    return (
      <Flex sx={{width: '100%', minHeight: '100%', flex: 1}}>
        <Flex sx={{flex: 1, flexDirection: 'column'}}>
          <Box sx={{height: 160}}>
            <MonacoEditor
              height="100%"
              width="100%"
              defaultLanguage="json"
              defaultValue={JSON.stringify(this.state.json, null, 2)}
              options={{tabSize: 2}}
              onChange={this.handleUpdateJson}
            />
          </Box>
          <Box sx={{flex: 1}}>
            {this.state.mode === 'react' ? (
              <MonacoEditor
                height="100%"
                width="100%"
                defaultLanguage="javascript"
                defaultValue={DEFAULT_CODE_VALUE}
                options={{tabSize: 2}}
                onMount={this.handleEditorMounted}
                onValidate={this.handleUpdateReactIframe}
                onSave={this.handleUpdateReactIframe}
              />
            ) : (
              <MonacoEditor
                height="100%"
                width="100%"
                defaultLanguage="markdown"
                defaultValue={EXAMPLE_MARKDOWN}
                options={{tabSize: 2}}
                onMount={this.handleEditorMounted}
                onChange={this.handleUpdateMarkdownIframe}
                onValidate={this.handleUpdateMarkdownIframe}
                onSave={this.handleUpdateMarkdownIframe}
              />
            )}
          </Box>
        </Flex>
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
