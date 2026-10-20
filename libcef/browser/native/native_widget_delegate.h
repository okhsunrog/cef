// Copyright 2014 The Chromium Embedded Framework Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found
// in the LICENSE file.

#ifndef CEF_LIBCEF_BROWSER_NATIVE_NATIVE_WIDGET_DELEGATE_H_
#define CEF_LIBCEF_BROWSER_NATIVE_NATIVE_WIDGET_DELEGATE_H_
#pragma once

#include <memory>

#include "base/memory/raw_ptr.h"
#include "ui/views/widget/widget_delegate.h"

namespace content {
class WebContents;
}

namespace views {
class WebView;
}

class CefNativeContentsView;

// Manages the views-based root window that hosts the web contents. This object
// will be deleted when the associated root window is destroyed.
class CefNativeWidgetDelegate : public views::WidgetDelegate {
 public:
  CefNativeWidgetDelegate(SkColor background_color,
                          bool always_on_top,
                          base::RepeatingClosure on_bounds_changed,
                          base::OnceClosure on_widget_destroying,
                          base::OnceClosure on_deleted = {});

  CefNativeWidgetDelegate(const CefNativeWidgetDelegate&) = delete;
  CefNativeWidgetDelegate& operator=(const CefNativeWidgetDelegate&) = delete;

  // Create the Widget and associated root window.
  void Init(gfx::AcceleratedWidget parent_widget,
            content::WebContents* web_contents,
            const gfx::Rect& bounds);

 private:
  friend class CefNativeContentsView;

  // WidgetDelegate methods:
  bool CanMaximize() const override { return true; }
  views::View* GetContentsView() override { return contents_view_.get(); }
  void WidgetIsZombie(views::Widget* widget) override;

  const SkColor background_color_;
  const bool always_on_top_;
  base::RepeatingClosure on_bounds_changed_;
  // Clear external raw pointers before releasing the client-owned Widget.
  base::OnceClosure on_widget_destroying_;
  // Complete browser teardown only after the contained Views are gone.
  base::OnceClosure on_deleted_;

  raw_ptr<views::View> contents_view_ = nullptr;
  raw_ptr<views::WebView> web_view_ = nullptr;

  std::unique_ptr<views::Widget> widget_;
};

#endif  // CEF_LIBCEF_BROWSER_NATIVE_NATIVE_WIDGET_DELEGATE_H_
