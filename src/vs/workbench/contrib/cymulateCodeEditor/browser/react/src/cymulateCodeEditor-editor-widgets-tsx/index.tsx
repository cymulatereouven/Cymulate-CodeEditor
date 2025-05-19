/*--------------------------------------------------------------------------------------
 *  Copyright 2025 Glass Devtools, Inc. All rights reserved.
 *  Licensed under the Apache License, Version 2.0. See LICENSE.txt for more information.
 *--------------------------------------------------------------------------------------*/

import { mountFnGenerator } from '../util/mountFnGenerator.js'
import { CymulateCodeEditorCommandBarMain } from './CymulateCodeEditorCommandBar.js'
import { CymulateCodeEditorSelectionHelperMain } from './CymulateCodeEditorSelectionHelper.js'

export const mountCymulateCodeEditorCommandBar = mountFnGenerator(CymulateCodeEditorCommandBarMain)

export const mountCymulateCodeEditorSelectionHelper = mountFnGenerator(CymulateCodeEditorSelectionHelperMain)

