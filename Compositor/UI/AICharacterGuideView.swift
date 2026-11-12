// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Xu Zhiping. All rights reserved.
// Xu Zhiping's original contributions and modifications only.
// Pre-existing upstream code retains its original copyright and license terms.
// See the repository LICENSING.md and applicable upstream license notices.

import SwiftUI
import AppKit

struct AICharacterGuideView: View {
    @Binding var plan: AICharacterPlan
    let references: [AIReferenceImage]
    @State private var showsPoseEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("人物创作 · 姿态 / 多人 / 换脸 / 换衣 / 换场景", isOn: $plan.enabled)
            if plan.enabled {
                Stepper("人数：\(plan.people.count)（最多 5 人）", value: Binding(get: { plan.people.count }, set: { plan.setCount($0) }), in: 1...5)
                TextField("人物位置、前后关系与互动，例如：人物 1 在左，人物 2 在右，相互对视", text: $plan.arrangement)
                    .textFieldStyle(.roundedBorder)
                ForEach(Array(plan.people.indices), id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("人物 \(index + 1)").font(.headline)
                        TextField("描述此人物，明确与其他人物的区别", text: $plan.people[index].description).textFieldStyle(.roundedBorder)
                        Toggle("换脸 · 严格使用此人物的身份脸图", isOn: $plan.people[index].replaceFace)
                        Toggle("换衣", isOn: $plan.people[index].changeClothes)
                        if plan.people[index].changeClothes {
                            TextField("新服装描述（或指定此人物的服饰参考图）", text: $plan.people[index].clothing).textFieldStyle(.roundedBorder)
                        }
                    }.padding(10).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                }
                Toggle("使用 IK 人偶姿态引导", isOn: $plan.usePose)
                HStack {
                    Button("编辑人偶姿态 · IK") { showsPoseEditor = true }
                    if let data = plan.poseGuidePNG, let image = NSImage(data: data) {
                        Image(nsImage: image).resizable().scaledToFit().frame(width: 160, height: 90)
                        Button("清除姿态图") { plan.poseGuidePNG = nil; plan.usePose = false; plan.poseDocument = "" }
                    }
                }
                Text("支持拖动关节的 CCD 逆运动学、关节限位、自动落地和多人独立姿态；人数变化后需重新保存姿态图。")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("换场景", isOn: $plan.changeScene)
                if plan.changeScene {
                    TextField("目标环境与照明（或指定场景参考图）", text: $plan.scene).textFieldStyle(.roundedBorder)
                }
                Text("在参考图下指定用途和人物。换脸仅使用指定脸图，严格保持可见的骨相、五官比例、轮廓及皮肤辨识特征。模型输出仍需检查是否保持本人身份。")
                    .font(.caption).foregroundStyle(.secondary)
                if let error = plan.validation(references: references.map(\.characterReference)) {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
            }
        }
        .sheet(isPresented: $showsPoseEditor) { AIMannequinEditor(plan: $plan) }
    }
}
