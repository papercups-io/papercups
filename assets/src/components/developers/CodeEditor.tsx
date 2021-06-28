import React from 'react';
import AceEditor, {IAceEditorProps} from 'react-ace';

import 'ace-builds/src-noconflict/mode-javascript';
import 'ace-builds/src-noconflict/theme-tomorrow';
import 'ace-builds/src-noconflict/theme-monokai';
import 'ace-builds/src-noconflict/ext-language_tools';
import 'ace-builds/src-min-noconflict/ext-spellcheck';
import 'ace-builds/src-min-noconflict/snippets/javascript';
import 'ace-builds/src-min-noconflict/ext-searchbox';

import ace from 'ace-builds/src-noconflict/ace';

ace.config.set(
  'basePath',
  'https://cdn.jsdelivr.net/npm/ace-builds@1.4.3/src-noconflict/'
);

ace.config.setModuleUrl(
  'ace/mode/javascript_worker',
  'https://cdn.jsdelivr.net/npm/ace-builds@1.4.3/src-noconflict/worker-javascript.js'
);

export const CodeEditor = (props: IAceEditorProps) => {
  const {
    mode = 'javascript',
    theme = 'tomorrow',
    height = '100%',
    width = '100%',
    tabSize = 2,
    editorProps = {},
    setOptions = {},
  } = props;

  return (
    <AceEditor
      mode={mode}
      theme={theme}
      name="CodeEditor-AceEditor"
      height={height}
      width={width}
      tabSize={tabSize}
      editorProps={{
        $blockScrolling: true,
        ...editorProps,
      }}
      setOptions={{
        enableBasicAutocompletion: true,
        enableLiveAutocompletion: true,
        enableSnippets: true,
        ...setOptions,
      }}
      {...props}
    />
  );
};

export default CodeEditor;
